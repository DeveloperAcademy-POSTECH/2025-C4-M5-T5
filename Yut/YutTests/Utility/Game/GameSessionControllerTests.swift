import Foundation
import Testing
@testable import Yut

@MainActor
@Suite(.serialized)
struct GameSessionControllerTests {
    @Test
    func retryWithoutActiveGameDoesNotRequestSynchronization() {
        let transport = TestGameTransport(isHost: false)
        let game = GameSessionController(transport: transport)
        defer { game.stop() }
        game.retry()
        #expect(transport.sent.isEmpty)
    }

    @Test
    func idleDisconnectDoesNotEraseNameInputNavigation() {
        let transport = TestGameTransport()
        let game = GameSessionController(transport: transport)
        var changes = 0
        game.onStateChanged = { _ in changes += 1 }
        transport.disconnect()
        #expect(changes == 0)
        #expect(game.start(players: [GamePlayer(name: "A", order: 0), GamePlayer(name: "B", order: 1)]))
        transport.disconnect()
        #expect(changes == 2)
        #expect(game.state == nil)
    }

    @Test
    func guestWaitsForHostAndRejectsWrongSenderGameAndOldRevision() throws {
        let hostID = UUID()
        let local = UUID()
        let players = [GamePlayer(name: "A", order: 0, deviceID: local), GamePlayer(name: "B", order: 1, deviceID: hostID)]
        let transport = TestGameTransport(isHost: false, localDeviceID: local, hostDeviceID: hostID, players: players)
        let game = GameSessionController(transport: transport)
        defer { game.stop() }
        var state = GameState(players: players)
        #expect(!game.receive(.startGame(state), from: UUID()))
        #expect(game.state == nil)
        #expect(game.receive(.startGame(state), from: hostID))
        #expect(game.submit(.startPlaying))
        #expect(game.state?.phase == .preparing)
        try state.apply(.startPlaying)
        #expect(game.receive(.state(state), from: hostID))
        #expect(!game.receive(.state(state), from: hostID))
        #expect(!game.receive(.state(GameState(players: players)), from: hostID))
        #expect(game.state == state)
        #expect(!game.receive(.startGame(GameState(players: players)), from: hostID))
        #expect(game.state == state)
    }

    @Test
    func hostChecksActualActorVersionAndAutomaticActionAuthority() throws {
        let local = UUID()
        let guest = UUID()
        let players = [GamePlayer(name: "A", order: 0, deviceID: local), GamePlayer(name: "B", order: 1, deviceID: guest)]
        let transport = TestGameTransport(localDeviceID: local, players: players)
        let game = GameSessionController(transport: transport)
        defer { game.stop() }
        #expect(game.start(players: players))
        #expect(game.submit(.startPlaying))
        let before = try #require(game.state)
        let request = GameRequest(gameID: before.id, revision: before.revision, action: .beginThrow)
        #expect(!game.receive(.request(request), from: guest))
        #expect(!game.receive(.request(request), from: UUID()))
        #expect(!game.receive(.request(.init(gameID: before.id, revision: before.revision - 1, action: .beginThrow)), from: local))
        #expect(!game.receive(.request(.init(gameID: before.id, revision: before.revision, action: .armThrow)), from: local))
        #expect(game.state == before)
        #expect(game.receive(.request(request), from: local))
        #expect(game.state?.phase == .gathering)
    }

    @Test
    func failedBroadcastIsAtomicAndRetryCommitsOnce() throws {
        let local = UUID()
        let transport = TestGameTransport(localDeviceID: local)
        let players = [GamePlayer(name: "A", order: 0, deviceID: local), GamePlayer(name: "B", order: 1)]
        transport.gamePlayers = players
        let game = GameSessionController(transport: transport)
        defer { game.stop() }
        #expect(game.start(players: players))
        let original = game.state
        transport.shouldFail = true
        #expect(!game.submit(.startPlaying))
        #expect(game.state == original)
        #expect(game.errorMessage != nil)
        transport.shouldFail = false
        game.retry()
        #expect(game.state?.phase == .readyToThrow)
        #expect(game.state?.revision == 1)
        #expect(game.errorMessage == nil)
    }

    @Test
    func hostArmsThrowAndCancelledTimerCannotArmNextTurn() async throws {
        let local = UUID()
        let transport = TestGameTransport(localDeviceID: local)
        transport.hasRemotePlayers = false
        let game = GameSessionController(transport: transport)
        defer { game.stop() }
        #expect(game.start(players: [GamePlayer(name: "A", order: 0, deviceID: local), GamePlayer(name: "B", order: 1, deviceID: local)]))
        #expect(game.submit(.startPlaying))
        #expect(game.submit(.beginThrow))
        #expect(game.submit(.cancelThrow))
        try await Task.sleep(for: .milliseconds(1400))
        #expect(game.state?.phase == .readyToThrow)
        #expect(game.submit(.beginThrow))
        try await Task.sleep(for: .milliseconds(1400))
        #expect(game.state?.phase == .waitingForShake)
    }

    @Test
    func sharedBoardAndFramesAreScopedToHostGameAndThrow() throws {
        let host = UUID()
        let local = UUID()
        let players = [GamePlayer(name: "A", order: 0, deviceID: host), GamePlayer(name: "B", order: 1, deviceID: local)]
        let transport = TestGameTransport(isHost: false, localDeviceID: local, hostDeviceID: host, players: players)
        let game = GameSessionController(transport: transport)
        defer { game.stop() }
        var state = GameState(players: players)
        #expect(game.receive(.startGame(state), from: host))
        let board = SharedBoard(anchorID: UUID(), worldMap: Data(), scale: 1)
        var messages: [GameMessage] = []
        game.onSpaceMessage = { messages.append($0) }
        #expect(!game.receive(.board(gameID: state.id, board), from: local))
        #expect(!game.receive(.board(gameID: UUID(), board), from: host))
        #expect(game.receive(.board(gameID: state.id, board), from: host))
        for action: GameAction in [.startPlaying, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch)] { try state.apply(action) }
        #expect(game.receive(.state(state), from: host))
        let poses = (0..<4).map { ThrowFrame.Pose(index: $0, position: [0, 1, 0], rotation: [0, 0, 0, 1], scale: [1, 1, 1]) }
        let frame = ThrowFrame(gameID: state.id, throwRevision: state.revision, poses: poses, isFinal: false)
        #expect(!game.receive(.throwFrame(frame), from: local))
        #expect(game.receive(.throwFrame(frame), from: host))
        #expect(!game.receive(.throwFrame(ThrowFrame(gameID: state.id, throwRevision: state.revision - 1, poses: poses, isFinal: false)), from: host))
        #expect(!game.receive(.throwFrame(ThrowFrame(gameID: state.id, throwRevision: state.revision, poses: Array(poses.prefix(3)), isFinal: false)), from: host))
        #expect(messages.count == 2)
    }

    @Test
    func guestActionsRoundTripThroughHostAndFramesRelayOnlyToOtherObservers() async throws {
        let hostID = UUID()
        let guestID = UUID()
        let observerID = UUID()
        let players = [GamePlayer(name: "Guest", order: 0, deviceID: guestID),
                       GamePlayer(name: "Host", order: 1, deviceID: hostID),
                       GamePlayer(name: "Observer", order: 2, deviceID: observerID)]
        let hostTransport = TestGameTransport(localDeviceID: hostID, players: players)
        let guestTransport = TestGameTransport(isHost: false, localDeviceID: guestID, hostDeviceID: hostID, players: players)
        let host = GameSessionController(transport: hostTransport)
        let guest = GameSessionController(transport: guestTransport)
        defer { host.stop(); guest.stop() }
        var frameRecipients: [UUID] = []
        hostTransport.delivery = { [weak guest] message, recipients in
            if case .throwFrame = message { frameRecipients = recipients ?? [] }
            guard recipients == nil || recipients?.contains(guestID) == true else { return }
            Task { @MainActor in _ = guest?.receive(message, from: hostID) }
        }
        guestTransport.delivery = { [weak host] message, _ in
            Task { @MainActor in _ = host?.receive(message, from: guestID) }
        }
        #expect(host.start(players: players))
        await settleMessages()
        #expect(host.state == guest.state)
        #expect(host.submit(.startPlaying))
        await settleMessages()
        #expect(guest.submit(.beginThrow))
        await settleMessages()
        #expect(host.state?.phase == .gathering)
        try await Task.sleep(for: .milliseconds(1400))
        await settleMessages()
        #expect(guest.state?.phase == .waitingForShake)
        #expect(guest.submit(.releaseThrow(launch: .testLaunch)))
        await settleMessages()
        let throwing = try #require(guest.state)
        #expect(host.state == throwing)
        let frame = ThrowFrame(gameID: throwing.id, throwRevision: throwing.revision,
            poses: (0..<4).map { .init(index: $0, position: [0, 0, 0], rotation: [0, 0, 0, 1], scale: [1, 1, 1]) },
            isFinal: true, timestamp: 0.5, collisionTimestamp: 0.2)
        var relayedCollision: TimeInterval?
        host.onSpaceMessage = { message in
            if case .throwFrame(let received) = message { relayedCollision = received.collisionTimestamp }
        }
        guest.sendSpace(.throwFrame(frame))
        await settleMessages()
        #expect(frameRecipients == [observerID])
        #expect(relayedCollision == 0.2)
        #expect(guest.submit(.recordThrow(.gae)))
        await settleMessages()
        try await Task.sleep(for: .milliseconds(1600))
        await settleMessages()
        #expect(guest.state?.phase == .selectingPiece)
        let piece = try #require(guest.state?.currentPieces.first)
        #expect(guest.submit(.selectPiece(piece.id)))
        await settleMessages()
        let destination = try #require(guest.state?.availableDestinations.first)
        #expect(guest.submit(.selectDestination(destination)))
        await settleMessages()
        #expect(host.state == guest.state)
        #expect(host.state?.currentPlayer?.deviceID == hostID)
        #expect(host.state?.pieces.first { $0.id == piece.id }?.cell == destination.cell)
    }

    private func settleMessages() async {
        for _ in 0..<20 { await Task.yield() }
    }

    @Test
    func frameAndLaunchValidationRejectsNonFiniteAndDuplicatePoses() throws {
        let pose = ThrowFrame.Pose(index: 0, position: [0, 0, 0], rotation: [0, 0, 0, 1], scale: [1, 1, 1])
        #expect(!ThrowFrame(gameID: UUID(), throwRevision: 4, poses: Array(repeating: pose, count: 4), isFinal: true).isValid)
        #expect(!YutThrowLaunch(cameraPosition: [.nan, 0, 0], cameraRotation: [0, 0, 0, 1], yutLocalRotation: [0, 0, 0, 1]).isValid)
        let message = GameMessage.throwFrame(ThrowFrame(gameID: UUID(), throwRevision: 4,
            poses: (0..<4).map { .init(index: $0, position: [0, 0, 0], rotation: [0, 0, 0, 1], scale: [1, 1, 1]) }, isFinal: true))
        #expect(try JSONDecoder().decode(GameMessage.self, from: JSONEncoder().encode(message)) == message)
    }
}
