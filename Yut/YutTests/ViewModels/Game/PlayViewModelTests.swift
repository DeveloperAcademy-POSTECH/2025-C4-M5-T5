import Foundation
import RealityKit
import Testing
@testable import Yut

@MainActor
@Suite(.serialized)
struct PlayViewModelTests {
    @Test
    func activeSceneErrorsArePublishedAndRetryClearsTheNotice() {
        let fixture = makeFixture()
        defer { fixture.game.stop() }
        #expect(fixture.game.receive(.startGame(GameState(players: fixture.transport.gamePlayers)), from: fixture.host))
        fixture.scene.arState.errorMessage = "공간 인식 실패"
        #expect(fixture.viewModel.errorMessage == "공간 인식 실패")
        fixture.viewModel.retry()
        #expect(fixture.viewModel.errorMessage == nil)
        #expect(fixture.scene.arState.errorMessage == nil)
        #expect(fixture.scene.retryCount == 1)
        fixture.game.onError?("게임 전송 실패")
        #expect(fixture.viewModel.errorMessage == "게임 전송 실패")
        fixture.transport.disconnect()
        #expect(fixture.viewModel.errorMessage == nil)
        #expect(fixture.navigator.homeCount == 1)
    }

    @Test
    func retryAndLateErrorsAfterGameEndCannotReopenAROrShowGameNotice() {
        let fixture = makeFixture()
        defer { fixture.game.stop() }
        #expect(fixture.game.receive(.startGame(GameState(players: fixture.transport.gamePlayers)), from: fixture.host))
        fixture.scene.pause()
        fixture.game.onError?("전송 실패")
        fixture.transport.disconnect()
        let sentCount = fixture.transport.sent.count

        fixture.viewModel.retry()
        fixture.game.onError?("이전 게임의 늦은 전송 실패")
        fixture.scene.arState.errorMessage = "이전 AR 작업의 늦은 실패"
        fixture.scene.pause()

        #expect(fixture.scene.retryCount == 0)
        #expect(fixture.scene.resumeCount == 0)
        #expect(fixture.transport.sent.count == sentCount)
        #expect(fixture.viewModel.errorMessage == nil)
        #expect(!fixture.viewModel.isSuspended)
    }

    @Test
    func disconnectBeforeQueuedStartDoesNotReopenPlayScreen() async throws {
        let session = MPCManager()
        let game = GameSessionController(transport: session)
        let navigation = NavigationManager()
        let scene = TestGameScene()
        let play = PlayViewModel(game: game, scene: scene, models: { [] }, navigator: navigation)
        let waiting = WaitingRoomViewModel(session: session, navigator: navigation)
        defer { session.disconnect() }
        let room = try #require(session.hostRoom(named: "Host"))
        navigation.showWaitingRoom(room)
        session.addLocalPlayer(named: "Friend")
        session.sendStartGameSignal()
        #expect(navigation.path.last == .playView)

        session.disconnect()
        try await Task.sleep(for: .milliseconds(100))

        #expect(waiting.players.isEmpty)
        #expect(game.state == nil)
        #expect(play.match == nil)
        #expect(navigation.path.isEmpty)
        play.resume()
        #expect(scene.resumeCount == 0)
    }

    @Test(arguments: [BoardPlacementPhase.scanning, .waitingForHost, .placing, .adjusting])
    func guestScansLocallyBeforeWaitingForHost(phase: BoardPlacementPhase) {
        let fixture = makeFixture()
        defer { fixture.game.stop() }
        fixture.scene.arState.placementPhase = phase
        #expect(fixture.viewModel.placementControlsPhase == .scanning)
        fixture.scene.arState.recognizedArea = fixture.scene.arState.minRequiredArea / 2
        #expect(fixture.viewModel.placementControlsPhase == .scanning)
        fixture.scene.arState.recognizedArea = fixture.scene.arState.minRequiredArea
        #expect(fixture.viewModel.placementControlsPhase == .waitingForHost)
        #expect(fixture.scene.arState.placementPhase == phase)
    }

    @Test
    func endedGameReturnsHomeAndCannotResumeAR() {
        let fixture = makeFixture()
        defer { fixture.game.stop() }
        #expect(fixture.game.receive(.startGame(GameState(players: fixture.transport.gamePlayers)), from: fixture.host))

        fixture.transport.disconnect()

        #expect(fixture.viewModel.match == nil)
        #expect(fixture.navigator.homeCount == 1)
        #expect(fixture.scene.arState.placementPhase == .loading)
        fixture.viewModel.resume()
        #expect(fixture.scene.resumeCount == 0)
    }

    @Test(arguments: [BoardPlacementPhase.scanning, .placing, .adjusting])
    func guestAlwaysSeesHostPlacementNotice(phase: BoardPlacementPhase) {
        let fixture = makeFixture()
        defer { fixture.game.stop() }
        fixture.scene.arState.placementPhase = phase
        fixture.scene.arState.recognizedArea = fixture.scene.arState.minRequiredArea

        #expect(fixture.viewModel.placementControlsPhase == .waitingForHost)
        #expect(fixture.scene.arState.placementPhase == phase)
    }

    @Test(arguments: [BoardPlacementPhase.loading, .relocalizing, .confirmed])
    func guestKeepsCameraPreparationAndRecoveryGuidance(phase: BoardPlacementPhase) {
        let fixture = makeFixture()
        defer { fixture.game.stop() }
        fixture.scene.arState.placementPhase = phase

        #expect(fixture.viewModel.placementControlsPhase == phase)
    }

    @Test(arguments: [BoardPlacementPhase.loading, .scanning, .placing, .adjusting, .waitingForHost, .relocalizing, .confirmed])
    func hostKeepsActualPlacementControls(phase: BoardPlacementPhase) {
        let transport = TestGameTransport()
        let game = GameSessionController(transport: transport)
        defer { game.stop() }
        let scene = TestGameScene()
        let viewModel = PlayViewModel(game: game, scene: scene, models: { [] }, navigator: TestGameNavigation())
        scene.arState.placementPhase = phase

        #expect(viewModel.placementControlsPhase == phase)
    }

    @Test(arguments: [true, false])
    func onlyHostCanRequestBoardPlacement(isHost: Bool) async {
        let local = UUID()
        let host = isHost ? local : UUID()
        let players = [GamePlayer(name: "Host", order: 0, deviceID: host),
                       GamePlayer(name: "Guest", order: 1, deviceID: isHost ? UUID() : local)]
        let transport = TestGameTransport(isHost: isHost, localDeviceID: local, hostDeviceID: host, players: players)
        let game = GameSessionController(transport: transport)
        defer { game.stop() }
        let scene = TestGameScene()
        let viewModel = PlayViewModel(game: game, scene: scene, models: { [] }, navigator: TestGameNavigation())

        if isHost { #expect(game.start(players: transport.gamePlayers)) }
        else {
            #expect(game.receive(.startGame(GameState(players: transport.gamePlayers)), from: host))
        }

        viewModel.beginPlacement()
        await viewModel.confirmBoard()

        #expect(scene.beginPlacementCount == (isHost ? 1 : 0))
        #expect(scene.confirmBoardCount == (isHost ? 1 : 0))
    }

    @Test(arguments: 0..<4)
    func scanUsesLocalPlayerWhileTurnAndResultKeepTheirOwnPlayer(localOrder: Int) throws {
        let players = (0..<4).map { GamePlayer(name: "Player\($0)", order: $0) }
        let host = players[0].deviceID
        let transport = TestGameTransport(isHost: false, localDeviceID: players[localOrder].deviceID,
            hostDeviceID: host, players: players)
        let game = GameSessionController(transport: transport)
        defer { game.stop() }
        let scene = TestGameScene()
        let viewModel = PlayViewModel(game: game, scene: scene, models: { [] }, navigator: TestGameNavigation())
        let actorOrder = (localOrder + 1) % 4
        var state = GameState(players: players, currentPlayerIndex: actorOrder)
        #expect(game.receive(.startGame(state), from: host))
        #expect(viewModel.scanningPieceType == PieceType.from(sequence: localOrder + 1))
        #expect(scene.scanningOrder == localOrder)
        #expect(viewModel.turnPieceType == PieceType.from(sequence: actorOrder + 1))
        for action: GameAction in [.startPlaying, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch), .recordThrow(.dho)] {
            try state.apply(action)
        }
        #expect(game.receive(.state(state), from: host))
        let resultColor = viewModel.resultPieceType
        #expect(resultColor == PieceType.from(sequence: actorOrder + 1))
        try state.apply(.dismissResult)
        try state.apply(.selectPiece(try #require(state.currentPieces.first).id))
        try state.apply(.selectDestination(try #require(state.availableDestinations.first)))
        #expect(game.receive(.state(state), from: host))
        #expect(viewModel.turnPieceType != resultColor)
        #expect(viewModel.resultPieceType == resultColor)
        #expect(viewModel.scanningPieceType == PieceType.from(sequence: localOrder + 1))
    }

    @Test
    func gatheringAppliesOneSceneSnapshotAndOneSound() throws {
        let fixture = makeFixture()
        defer { fixture.game.stop() }
        var state = GameState(players: fixture.transport.gamePlayers)
        #expect(fixture.game.receive(.startGame(state), from: fixture.host))
        try state.apply(.startPlaying)
        #expect(fixture.game.receive(.state(state), from: fixture.host))
        let renderCount = fixture.scene.renderCount
        try state.apply(.beginThrow)
        #expect(fixture.game.receive(.state(state), from: fixture.host))
        #expect(fixture.scene.renderCount == renderCount + 1)
        #expect(fixture.scene.gatheringSoundCount == 1)
        #expect(fixture.viewModel.match?.phase == .gathering)
    }

    @Test
    func interruptionCancelsCurrentThrowAndLateResultCannotAdvanceTurn() throws {
        let fixture = makeFixture()
        defer { fixture.game.stop() }
        var state = GameState(players: fixture.transport.gamePlayers)
        for action: GameAction in [.startPlaying, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch)] { try state.apply(action) }
        #expect(fixture.game.receive(.startGame(GameState(id: state.id, players: state.players, pieces: state.pieces)), from: fixture.host))
        #expect(fixture.game.receive(.state(state), from: fixture.host))
        fixture.scene.pause()
        #expect(fixture.viewModel.isSuspended)
        let request = try #require(fixture.transport.sent.last)
        guard case .request(let cancellation) = request else { Issue.record("취소 요청 누락"); return }
        #expect(cancellation.action == .cancelThrow)
        try state.apply(cancellation.action)
        #expect(fixture.game.receive(.state(state), from: fixture.host))
        let sentCount = fixture.transport.sent.count
        fixture.scene.onResult?(.mo)
        #expect(fixture.transport.sent.count == sentCount)
        fixture.viewModel.resume()
        #expect(!fixture.viewModel.isSuspended)
        #expect(fixture.viewModel.match?.phase == .readyToThrow)
    }

    @Test
    func recoveredTrackingRestoresInputAndRetryRestartsSuspendedScene() throws {
        let fixture = makeFixture()
        defer { fixture.game.stop() }
        #expect(fixture.game.receive(.startGame(GameState(players: fixture.transport.gamePlayers)), from: fixture.host))
        fixture.scene.pause()
        fixture.viewModel.retry()
        #expect(fixture.scene.retryCount == 1)
        fixture.scene.pause()
        fixture.scene.arState.placementPhase = .confirmed
        fixture.viewModel.resumePhase()
        #expect(!fixture.viewModel.isSuspended)
        #expect(fixture.viewModel.canAct)
    }

    @Test
    func finishShowsActualWinnerAndRematchReturnsToGameWithNewIdentity() throws {
        let fixture = makeFixture()
        defer { fixture.game.stop() }
        let players = fixture.transport.gamePlayers
        var state = GameState(players: players, pieces: [
            GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: GameBoard.routes[0].count - 1)),
            GamePiece(playerID: players[0].id, position: .finished),
            GamePiece(playerID: players[1].id), GamePiece(playerID: players[1].id)
        ])
        for action: GameAction in [.startPlaying, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch), .recordThrow(.dho), .dismissResult] { try state.apply(action) }
        try state.apply(.selectPiece(try #require(state.currentPieces.first).id))
        try state.apply(.selectDestination(try #require(state.availableDestinations.first)))
        #expect(fixture.game.receive(.startGame(GameState(id: state.id, players: state.players, pieces: state.pieces)), from: fixture.host))
        #expect(fixture.game.receive(.state(state), from: fixture.host))
        #expect(fixture.navigator.winnerCount == 1)
        let winner = WinnerViewModel(game: fixture.game)
        #expect(winner.winnerName == "A")
        winner.playAgain()
        #expect(fixture.transport.sent.last == .requestRematch)
        let next = GameState(players: players)
        #expect(fixture.game.receive(.startGame(next), from: fixture.host))
        #expect(fixture.viewModel.match?.id != state.id)
        #expect(fixture.navigator.gameCount == 2)
        #expect(fixture.viewModel.match?.pieces.allSatisfy { $0.position == .home } == true)
    }

    private func makeFixture() -> (game: GameSessionController, transport: TestGameTransport, scene: TestGameScene, viewModel: PlayViewModel, navigator: TestGameNavigation, host: UUID) {
        let local = UUID()
        let host = UUID()
        let transport = TestGameTransport(isHost: false, localDeviceID: local, hostDeviceID: host,
            players: [GamePlayer(name: "A", order: 0, deviceID: local), GamePlayer(name: "B", order: 1, deviceID: host)])
        let game = GameSessionController(transport: transport)
        let scene = TestGameScene()
        let navigator = TestGameNavigation()
        let viewModel = PlayViewModel(game: game, scene: scene, models: { [] }, navigator: navigator)
        return (game, transport, scene, viewModel, navigator, host)
    }
}

@MainActor
private final class TestGameScene: GameSceneManaging {
    let arState = ARState(gameManager: GameManager())
    let gatheringFrames = GatheringFrameCache()
    var onAction: ((GameAction) -> Void)?
    var onWillThrow: (() -> Bool)?
    var onResult: ((YutResult) -> Void)?
    var onSpaceMessage: ((GameMessage) -> Void)?
    var onSuspended: (() -> Void)?
    var retryCount = 0
    var renderCount = 0
    var gatheringSoundCount = 0
    var scanningOrder: Int?
    var beginPlacementCount = 0
    var confirmBoardCount = 0
    var resumeCount = 0
    func setScanningPlayer(order: Int?) { scanningOrder = order }
    init() { arState.placementPhase = .confirmed }
    func configure(isHost: Bool, hasRemotePlayers: Bool) {}
    func makeView() -> ARView { ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false) }
    func resume() { resumeCount += 1; arState.placementPhase = .confirmed }
    func pause() { arState.placementPhase = .relocalizing; onSuspended?() }
    func reset() { arState.placementPhase = .loading }
    func retry() { retryCount += 1; resume() }
    func beginPlacement() { beginPlacementCount += 1 }
    func confirmBoard() async { confirmBoardCount += 1 }
    func shareSavedBoard() {}
    func render(_ state: GameState, models: [PlayerModel], canAct: Bool, force: Bool) { renderCount += 1 }
    func startMotion() {}
    func throwManually() { _ = onWillThrow?() }
    func playGatheringSound() { gatheringSoundCount += 1 }
    func captureLaunch() throws -> YutThrowLaunch { .testLaunch }
    func receiveBoard(_ board: SharedBoard) throws {}
    func receiveCollaboration(_ data: Data) throws {}
    func showRemoteFrame(_ frame: ThrowFrame) {}
}
