import Foundation

/// YutAR의 규칙·버전 검증과 호스트 타이머를 사용한다. 실제 윷 투사는 원본 AR 서비스가 수행한다.
@MainActor
final class GameSessionController {
    private(set) var state: GameState?
    private(set) var errorMessage: String?
    var onStateChanged: ((GameState?) -> Void)?
    var onError: ((String) -> Void)?
    var onSpaceMessage: ((GameMessage) -> Void)?
    var onSynchronizationRequested: (() -> Void)?

    let transport: any GameTransporting
    private var transitionTask: Task<Void, Never>?
    private var failedAction: GameAction?
    private var failedRequest: GameRequest?

    var canAct: Bool { state?.currentPlayer?.deviceID == transport.localDeviceID }
    var isHost: Bool { transport.isHost }
    var hasRemotePlayers: Bool { transport.hasRemotePlayers }
    var throwRevision: Int? {
        guard let state else { return nil }
        if state.phase == .throwing { return state.revision }
        if state.phase == .showingResult { return state.revision - 1 }
        return nil
    }

    init(transport: any GameTransporting) {
        self.transport = transport
        transport.onStartGame = { [weak self] in
            guard let self else { return false }
            return start(players: self.transport.gamePlayers)
        }
        transport.onGameMessage = { [weak self] message, sender in self?.receive(message, from: sender) ?? false }
        transport.onGameStopped = { [weak self] in self?.stop() }
    }

    @discardableResult
    func start(players: [GamePlayer]) -> Bool {
        guard isHost, (2...4).contains(players.count), Set(players.map(\.id)).count == players.count,
              state == nil || state?.phase == .finished else { return false }
        let next = GameState(players: players)
        guard send(.startGame(next)) else { return false }
        install(next)
        return true
    }

    func stop() {
        let hadGame = state != nil
        transitionTask?.cancel()
        transitionTask = nil
        failedAction = nil
        failedRequest = nil
        state = nil
        errorMessage = nil
        if hadGame { onStateChanged?(nil) }
    }

    /// 참가자는 확정 스냅샷을 기다리며 로컬 상태를 미리 변경하지 않는다.
    @discardableResult
    func submit(_ action: GameAction) -> Bool {
        guard let state else { return false }
        let request = GameRequest(gameID: state.id, revision: state.revision, action: action)
        if isHost { return receiveRequest(request, from: transport.localDeviceID) }
        let sent = send(.request(request))
        failedRequest = sent ? nil : request
        return sent
    }

    func requestRematch() {
        guard state?.phase == .finished else { return }
        if isHost { start(players: transport.gamePlayers) }
        else { send(.requestRematch) }
    }

    func retry() {
        guard state != nil else { return }
        errorMessage = nil
        if let action = failedAction { _ = apply(action) }
        else if let request = failedRequest {
            if send(.request(request)) { failedRequest = nil }
        } else if isHost, let state {
            if send(.state(state)) { scheduleTransition(for: state) }
            onSynchronizationRequested?()
        } else { send(.requestSynchronization) }
    }

    /// 공간 데이터도 현재 게임·발신 기기를 검증한 뒤 AR 계층으로 전달한다.
    @discardableResult
    func receive(_ message: GameMessage, from sender: UUID) -> Bool {
        let fromHost = sender == transport.hostDeviceID
        switch message {
        case .startGame(let next):
            guard !isHost, fromHost, state == nil || state?.phase == .finished,
                  next.phase == .preparing, state?.id != next.id, validSnapshot(next) else { return false }
            install(next)
        case .state(let next):
            guard !isHost, fromHost, state?.id == next.id,
                  next.revision > (state?.revision ?? -1), validSnapshot(next) else { return false }
            install(next)
        case .request(let request):
            return receiveRequest(request, from: sender)
        case .requestRematch:
            guard isHost, state?.phase == .finished, isMember(sender) else { return false }
            return start(players: transport.gamePlayers)
        case .requestSynchronization:
            guard isHost, isMember(sender), let state else { return false }
            _ = send(.state(state), to: [sender])
            onSynchronizationRequested?()
        case .board(let gameID, _):
            guard !isHost, fromHost, state?.id == gameID else { return false }
            onSpaceMessage?(message)
        case .collaboration(let gameID, _, _):
            guard state?.id == gameID, isHost ? isMember(sender) : fromHost else { return false }
            onSpaceMessage?(message)
            if isHost { send(message, excluding: sender) }
        case .throwFrame(let frame):
            guard frame.isValid, let state, frame.gameID == state.id, frame.throwRevision == throwRevision,
                  isHost ? sender == state.currentPlayer?.deviceID : fromHost else { return false }
            onSpaceMessage?(message)
            if isHost { send(message, excluding: sender) }
        }
        return true
    }

    func sendSpace(_ message: GameMessage) {
        guard state != nil else { return }
        _ = send(message)
    }

    private func validSnapshot(_ next: GameState) -> Bool {
        (2...4).contains(next.players.count) && next.players.indices.contains(next.currentPlayerIndex)
            && Set(next.players.map(\.id)).count == next.players.count
            && next.players.contains { $0.deviceID == transport.localDeviceID }
            && next.pieces.count == next.players.count * 2
            && Set(next.pieces.map(\.id)).count == next.pieces.count
            && next.players.allSatisfy { player in next.pieces.filter { $0.playerID == player.id }.count == 2 }
            && next.pieces.allSatisfy { piece in next.players.contains { $0.id == piece.playerID } }
    }

    private func isMember(_ id: UUID) -> Bool { state?.players.contains { $0.deviceID == id } == true }

    private func receiveRequest(_ request: GameRequest, from sender: UUID) -> Bool {
        guard isHost, let state, request.gameID == state.id, isMember(sender) else { return false }
        guard request.revision == state.revision else {
            _ = send(.state(state), to: [sender])
            return false
        }
        switch request.action {
        case .armThrow, .dismissResult: return false
        case .startPlaying:
            guard sender == transport.localDeviceID else { return false }
        default:
            guard sender == state.currentPlayer?.deviceID else { return false }
        }
        return apply(request.action)
    }

    private func apply(_ action: GameAction) -> Bool {
        guard var next = state else { return false }
        do {
            try next.apply(action)
            guard send(.state(next)) else { failedAction = action; return false }
            failedAction = nil
            install(next)
            return true
        } catch {
            fail(error)
            return false
        }
    }

    private func install(_ next: GameState) {
        errorMessage = nil
        state = next
        onStateChanged?(next)
        scheduleTransition(for: next)
    }

    private func scheduleTransition(for next: GameState) {
        transitionTask?.cancel()
        guard isHost else { return }
        let action: GameAction
        let duration: Duration
        switch next.phase {
        case .gathering: action = .armThrow; duration = .milliseconds(1300)
        case .showingResult, .showingBonus: action = .dismissResult; duration = .milliseconds(1500)
        default: return
        }
        transitionTask = Task { [weak self] in
            do { try await Task.sleep(for: duration) } catch { return }
            guard let self, state?.id == next.id, state?.revision == next.revision else { return }
            _ = apply(action)
        }
    }

    @discardableResult
    private func send(_ message: GameMessage, to recipients: [UUID]? = nil) -> Bool {
        guard transport.hasRemotePlayers else { return true }
        do { try transport.sendGame(message, to: recipients); return true }
        catch { fail(error); return false }
    }

    private func send(_ message: GameMessage, excluding sender: UUID) {
        let ids = Set(state?.players.map(\.deviceID) ?? []).subtracting([sender, transport.localDeviceID])
        if !ids.isEmpty { _ = send(message, to: Array(ids)) }
    }

    private func fail(_ error: Error) {
        errorMessage = error.localizedDescription
        onError?(error.localizedDescription)
    }
}
