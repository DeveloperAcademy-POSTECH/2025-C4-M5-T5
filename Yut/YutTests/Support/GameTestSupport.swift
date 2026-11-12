import AVFoundation
import Foundation
import RealityKit
import simd
import Testing
@testable import Yut

extension YutThrowLaunch {
    static var testLaunch: YutThrowLaunch {
        YutThrowLaunch(cameraPosition: [0, 1.3, 1.3], cameraRotation: [0, 0, 0, 1],
            yutLocalRotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 1]).vector)
    }
}

@MainActor
final class TestGameTransport: GameTransporting {
    enum Failure: Error { case unavailable }
    var isHost: Bool
    let localDeviceID: UUID
    var hostDeviceID: UUID?
    var hasRemotePlayers = true
    var gamePlayers: [GamePlayer]
    var onGameMessage: ((GameMessage, UUID) -> Bool)?
    var onStartGame: (() -> Bool)?
    var onGameStopped: (() -> Void)?
    var delivery: ((GameMessage, [UUID]?) -> Void)?
    var sent: [GameMessage] = []
    var shouldFail = false

    init(isHost: Bool = true, localDeviceID: UUID = UUID(), hostDeviceID: UUID? = nil, players: [GamePlayer] = []) {
        self.isHost = isHost
        self.localDeviceID = localDeviceID
        self.hostDeviceID = isHost ? localDeviceID : hostDeviceID
        gamePlayers = players
    }
    func sendGame(_ message: GameMessage, to recipients: [UUID]?) throws {
        if shouldFail { throw Failure.unavailable }
        sent.append(message)
        delivery?(message, recipients)
    }
    func disconnect() { onGameStopped?() }
}

@MainActor
final class TestGameNavigation: GameNavigating {
    var gameCount = 0
    var winnerCount = 0
    var homeCount = 0
    func showGame() { gameCount += 1 }
    func showWinner() { winnerCount += 1 }
    func returnHome() { homeCount += 1 }
}

/// 실제 통신 없이 입력부터 확정 스냅샷까지 같은 규칙 모델로 왕복한다.
@MainActor
final class BoardTestFixture {
    private enum Failure: Error { case timeout }
    let scene: ARCoordinator
    let game: GameSessionController
    let transport: TestGameTransport
    let models: [PlayerModel]
    let viewModel: PlayViewModel
    var state: GameState

    init(sound: (any GameSoundPlaying)? = nil) throws {
        let local = UUID()
        let host = UUID()
        models = [PlayerModel(name: "A", sequence: 1, peerID: .init(displayName: "A"), deviceID: local, preparePieces: false),
                  PlayerModel(name: "B", sequence: 2, peerID: .init(displayName: "B"), deviceID: host, preparePieces: false)]
        let players = models.map { GamePlayer(id: $0.id, name: $0.name, order: $0.sequence - 1, deviceID: $0.deviceID) }
        var state = GameState(players: players, pieces: [
            GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 1)),
            GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 3)),
            GamePiece(playerID: players[1].id), GamePiece(playerID: players[1].id)
        ])
        for action: GameAction in [.startPlaying, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch), .recordThrow(.dho), .dismissResult] { try state.apply(action) }
        self.state = state
        transport = TestGameTransport(isHost: false, localDeviceID: local, hostDeviceID: host, players: players)
        game = GameSessionController(transport: transport)
        scene = ARCoordinator(state: ARState(gameManager: GameManager()), assets: AssetCacheManager(),
                              sound: sound ?? SoundService(audioSession: AVAudioSession.sharedInstance()))
        viewModel = PlayViewModel(game: game, scene: scene, models: { [models] in models }, navigator: TestGameNavigation())
        transport.delivery = { [weak self] message, _ in
            guard let self, case .request(let request) = message else { return }
            do {
                try self.state.apply(request.action)
                _ = self.transport.onGameMessage?(.state(self.state), host)
            } catch { Issue.record(error) }
        }
    }

    func prepare() async throws -> ARView {
        scene.configure(isHost: true, hasRemotePlayers: false)
        let view = scene.makeView()
        view.frame = CGRect(x: 0, y: 0, width: 400, height: 800)
        for _ in 0..<500 {
            if scene.arState.placementPhase == .scanning { break }
            if let error = scene.arState.errorMessage { Issue.record("\(error)"); throw Failure.timeout }
            try await Task.sleep(for: .milliseconds(10))
        }
        guard scene.arState.placementPhase == .scanning else { throw Failure.timeout }
        scene.beginPlacement()
        scene.placeBoard(at: CGPoint(x: 200, y: 400))
        await scene.confirmBoard()
        let initial = GameState(id: state.id, players: state.players, pieces: state.pieces)
        _ = game.receive(.startGame(initial), from: transport.hostDeviceID ?? UUID())
        _ = game.receive(.state(state), from: transport.hostDeviceID ?? UUID())
        return view
    }
}
