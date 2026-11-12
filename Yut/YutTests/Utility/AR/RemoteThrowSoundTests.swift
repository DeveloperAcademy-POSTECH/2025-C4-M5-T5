import Foundation
import RealityKit
import Testing
@testable import Yut

@MainActor
@Suite(.serialized)
struct RemoteThrowSoundTests {
    @Test
    func collisionReceivedWhilePausedDoesNotPlayOnResume() async throws {
        let sound = RecordingGameSound()
        let fixture = try BoardTestFixture(sound: sound)
        var state = GameState(players: fixture.state.players, currentPlayerIndex: 1)
        for action: GameAction in [.startPlaying, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch)] {
            try state.apply(action)
        }
        fixture.state = state
        _ = try await fixture.prepare()
        defer { fixture.scene.reset() }
        fixture.scene.pause()
        fixture.scene.showRemoteFrame(ThrowFrame(gameID: state.id, throwRevision: state.revision,
            poses: (0..<4).map { .init(index: $0, position: [0, 0, 0], rotation: [0, 0, 0, 1], scale: [1, 1, 1]) },
            isFinal: true, sequence: 3, timestamp: 0.5, collisionTimestamp: 0.25))
        fixture.viewModel.resume()
        for _ in 0..<100 {
            if fixture.scene.arState.placementPhase == .confirmed { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(fixture.scene.arState.placementPhase == .confirmed)
        #expect(sound.collisionCount == 0)
    }

    @Test
    func observerPlaysCollisionOncePerThrowAndNeverReplaysAfterPause() async throws {
        let sound = RecordingGameSound()
        let fixture = try BoardTestFixture(sound: sound)
        var state = GameState(players: fixture.state.players, currentPlayerIndex: 1)
        for action: GameAction in [.startPlaying, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch)] {
            try state.apply(action)
        }
        fixture.state = state
        let view = try await fixture.prepare()
        defer { fixture.scene.reset() }
        let poses = (0..<4).map { ThrowFrame.Pose(index: $0, position: [Float($0), 0, 0],
            rotation: [0, 0, 0, 1], scale: [1, 1, 1]) }
        let final = ThrowFrame(gameID: state.id, throwRevision: state.revision, poses: poses,
            isFinal: true, sequence: 3, timestamp: 0.5, collisionTimestamp: 0.25)

        fixture.scene.showRemoteFrame(final)
        fixture.scene.showRemoteFrame(final)
        #expect(sound.collisionCount == 1)
        let name = try #require(fixture.scene.assetCacheManager.cachedModel(named: "Yut1")).name
        let entity = try #require(view.scene.anchors.compactMap { $0.findEntity(named: name) }.first)
        #expect(entity.components[PhysicsBodyComponent.self] == nil)
        #expect(entity.components[CollisionComponent.self] == nil)

        fixture.scene.pause()
        fixture.scene.showRemoteFrame(final)
        fixture.viewModel.resume()
        for _ in 0..<100 {
            if fixture.scene.arState.placementPhase == .confirmed { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(sound.collisionCount == 1)

        for action: GameAction in [.recordThrow(.nak), .dismissResult, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch)] {
            try state.apply(action)
        }
        #expect(fixture.game.receive(.state(state), from: try #require(fixture.transport.hostDeviceID)))
        fixture.scene.showRemoteFrame(final)
        #expect(sound.collisionCount == 1)
        fixture.scene.showRemoteFrame(ThrowFrame(gameID: state.id, throwRevision: state.revision, poses: poses,
            isFinal: true, sequence: 1, timestamp: 0.4, collisionTimestamp: 0.2))
        #expect(sound.collisionCount == 2)
    }
}

@MainActor
private final class RecordingGameSound: GameSoundPlaying {
    var collisionCount = 0
    func prepare() {}
    func stop() {}
    func playCollectYutSound() {}
    func playCollisionSound() { collisionCount += 1 }
}
