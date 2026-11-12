import Combine
import Foundation
import OSLog

/// 공유 단계와 로컬 AR 준비를 조정한다. 투사는 원본 실행기가 담당하며 여기서 물리 수치를 계산하지 않는다.
@MainActor
final class PlayViewModel: ObservableObject {
    @Published private(set) var match: GameState?
    @Published private(set) var isSuspended = false
    @Published private(set) var resultPieceType: PieceType?
    @Published private(set) var errorMessage: String?
    @Published var localError: String? { didSet { refreshError() } }
    let scene: any GameSceneManaging
    let game: GameSessionController
    private let models: () -> [PlayerModel]
    private let navigator: any GameNavigating
    private var needsThrowCancellation = false
    private var cancellationRevision: Int?
    private var sceneError: String?
    private var errorObservation: AnyCancellable?
    private let signposter = OSSignposter(subsystem: "Yut", category: "ARPerformance")

    var canAct: Bool { game.canAct && !isSuspended }
    var isHost: Bool { game.isHost }
    var playerName: String { match?.currentPlayer?.name ?? "플레이어" }
    var currentOrder: Int { match?.currentPlayer?.order ?? 0 }
    var turnPieceType: PieceType? { match?.currentPlayer.flatMap { PieceType.from(sequence: $0.order + 1) } }
    var scanningPlayerOrder: Int? { match?.players.first { $0.deviceID == game.transport.localDeviceID }?.order }
    var scanningPieceType: PieceType? { scanningPlayerOrder.flatMap { PieceType.from(sequence: $0 + 1) } }

    /// 참가자도 자기 기기로 공간을 스캔하며, 준비가 끝나면 방장의 배치를 기다린다.
    var placementControlsPhase: BoardPlacementPhase {
        let phase = scene.arState.placementPhase
        if !isHost, [.scanning, .placing, .adjusting, .waitingForHost].contains(phase) {
            return scene.arState.recognizedArea >= scene.arState.minRequiredArea ? .waitingForHost : .scanning
        }
        return phase
    }

    init(game: GameSessionController, scene: any GameSceneManaging, models: @escaping () -> [PlayerModel], navigator: any GameNavigating) {
        self.game = game
        self.scene = scene
        self.models = models
        self.navigator = navigator
        game.onStateChanged = { [weak self] in self?.apply($0) }
        game.onError = { [weak self] error in
            guard let self, match != nil else { return }
            localError = error
        }
        errorObservation = scene.arState.$errorMessage.sink { [weak self] error in
            self?.sceneError = error
            self?.refreshError()
        }
        game.onSpaceMessage = { [weak self] in self?.receiveSpace($0) }
        game.onSynchronizationRequested = { [weak scene] in scene?.shareSavedBoard() }
        scene.onAction = { [weak game] in _ = game?.submit($0) }
        scene.onWillThrow = { [weak self] in self?.releaseThrow() ?? false }
        scene.onResult = { [weak self] result in
            guard let self, !isSuspended, game.canAct, match?.phase == .throwing else { return }
            _ = game.submit(.recordThrow(result))
        }
        scene.onSpaceMessage = { [weak game] in game?.sendSpace($0) }
        scene.onSuspended = { [weak self] in self?.suspended() }
    }

    private func apply(_ state: GameState?) {
        let previous = match
        match = state
        guard let state else {
            resultPieceType = nil
            scene.reset()
            dismissError()
            isSuspended = false
            needsThrowCancellation = false
            cancellationRevision = nil
            navigator.returnHome()
            return
        }
        if previous?.id != state.id { resultPieceType = nil; dismissError() }
        refreshError()
        if [.gathering, .throwing].contains(state.phase)
            || (resultPieceType == nil && [.showingResult, .showingBonus].contains(state.phase)) {
            resultPieceType = state.currentPlayer.flatMap { PieceType.from(sequence: $0.order + 1) }
        }
        scene.setScanningPlayer(order: scanningPlayerOrder)
        scene.configure(isHost: game.isHost, hasRemotePlayers: game.hasRemotePlayers)
        scene.render(state, models: models(), canAct: game.canAct && !isSuspended, force: false)
        if state.phase == .finished { navigator.showWinner() }
        else if previous?.id != state.id || previous?.phase == .finished { navigator.showGame() }
        if state.phase == .readyToThrow { needsThrowCancellation = false; cancellationRevision = nil }
        cancelInterruptedThrowIfNeeded()
        if previous?.phase != state.phase, state.phase == .gathering { scene.playGatheringSound() }
        // 이미 렌더한 스냅샷을 다시 적용하지 않고 현재 단계의 센서만 준비한다.
        startMotionIfNeeded()
    }

    func beginThrow() {
        guard canAct, match?.phase == .readyToThrow, scene.arState.placementPhase == .confirmed else { return }
        signposter.emitEvent("GatherInput")
        _ = game.submit(.beginThrow)
    }

    @discardableResult
    private func releaseThrow() -> Bool {
        guard canAct, !needsThrowCancellation, match?.phase == .waitingForShake else { return false }
        do { return game.submit(.releaseThrow(launch: try scene.captureLaunch())) }
        catch { localError = error.localizedDescription; return false }
    }

    func throwManually() { guard canAct else { return }; scene.throwManually() }
    func startPlaying() { guard isHost, scene.arState.placementPhase == .confirmed else { return }; _ = game.submit(.startPlaying) }
    func beginPlacement() {
        guard isHost else { return }
        scene.beginPlacement()
    }
    func confirmBoard() async {
        guard isHost, let expectedID = match?.id else { return }
        await scene.confirmBoard()
        guard match?.id == expectedID else { return }
        resumePhase()
    }
    func placeNewPiece() {
        guard canAct, let piece = match?.currentPieces.first(where: { $0.position == .home }) else { return }
        _ = game.submit(.selectPiece(piece.id))
    }
    func cancelSelection() { guard canAct else { return }; _ = game.submit(.cancelSelection) }
    func resolveCarry(_ carry: Bool) { guard canAct else { return }; _ = game.submit(.resolveCarry(carry)) }
    func leaveRoom() { game.transport.disconnect() }

    func pause() { scene.pause() }
    func resume() {
        guard match != nil else {
            returnHomeIfEnded()
            return
        }
        isSuspended = false
        scene.setScanningPlayer(order: scanningPlayerOrder)
        scene.configure(isHost: game.isHost, hasRemotePlayers: game.hasRemotePlayers)
        scene.resume()
        cancelInterruptedThrowIfNeeded()
        resumePhase()
    }
    func resumePhase() {
        guard match != nil, scene.arState.placementPhase == .confirmed else { return }
        isSuspended = false
        if let match { scene.render(match, models: models(), canAct: game.canAct, force: false) }
        startMotionIfNeeded()
    }

    private func startMotionIfNeeded() {
        guard !isSuspended, scene.arState.placementPhase == .confirmed,
              game.canAct, match?.phase == .waitingForShake, !needsThrowCancellation else { return }
        scene.startMotion()
    }
    func retry() {
        guard let id = match?.id, game.state?.id == id else { returnHomeIfEnded(); return }
        let wasSuspended = isSuspended
        let hadSceneError = scene.arState.errorMessage != nil
        dismissError()
        game.retry()
        guard match?.id == id, game.state?.id == id else { return }
        isSuspended = false
        if hadSceneError || wasSuspended { scene.retry() }
        else { resumePhase() }
    }

    func returnHomeIfEnded() {
        guard match == nil else { return }
        dismissError()
        isSuspended = false
        navigator.returnHome()
    }

    private func dismissError() {
        localError = nil
        scene.arState.errorMessage = nil
        refreshError()
    }

    private func refreshError() {
        let message = match == nil || match?.phase == .finished ? nil : localError ?? sceneError
        if errorMessage != message { errorMessage = message }
    }

    private func suspended() {
        guard match != nil else { isSuspended = false; return }
        isSuspended = true
        if game.canAct, let phase = match?.phase, [.gathering, .waitingForShake, .throwing].contains(phase) {
            needsThrowCancellation = true
            cancelInterruptedThrowIfNeeded()
        }
    }

    private func cancelInterruptedThrowIfNeeded() {
        guard needsThrowCancellation, game.canAct, let match, [.gathering, .waitingForShake, .throwing].contains(match.phase),
              cancellationRevision != match.revision else { return }
        cancellationRevision = match.revision
        _ = game.submit(.cancelThrow)
    }

    private func receiveSpace(_ message: GameMessage) {
        do {
            switch message {
            case .board(_, let board): try scene.receiveBoard(board)
            case .collaboration(_, let data, _): try scene.receiveCollaboration(data)
            case .throwFrame(let frame): scene.showRemoteFrame(frame)
            default: break
            }
        } catch { localError = error.localizedDescription }
    }
}
