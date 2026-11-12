import Foundation
import simd
import Testing
@testable import Yut

struct RemoteThrowPlaybackTests {
    @Test
    func collisionUsesTheSameDelayedPlayheadAndIsConsumedOnce() {
        let game = UUID()
        var playback = RemoteThrowPlayback(delay: 0.1)
        playback.append(frame(game, sequence: 1, time: 0, x: 0), receivedAt: 10)
        var collision = frame(game, sequence: 2, time: 0.1, x: 1)
        collision.collisionTimestamp = 0.08
        playback.append(collision, receivedAt: 10.1)
        let collisionCue1 = playback.consumeCollision(at: 10.17)
        #expect(!collisionCue1)
        let collisionCue2 = playback.consumeCollision(at: 10.19)
        #expect(collisionCue2)
        let collisionCue3 = playback.consumeCollision(at: 11)
        #expect(!collisionCue3)
        var later = frame(game, sequence: 3, time: 0.2, x: 2, final: true)
        later.collisionTimestamp = 0.08
        playback.append(later, receivedAt: 10.2)
        let collisionCue4 = playback.consumeCollision(at: 12)
        #expect(!collisionCue4)
    }

    @Test
    func reliableFinalRecoversCollisionWhenEarlierFramesAreLost() {
        var playback = RemoteThrowPlayback()
        var final = frame(UUID(), sequence: 5, time: 0.5, x: 0, final: true)
        final.collisionTimestamp = 0.2
        playback.append(final, receivedAt: 20)
        let collisionPose5 = playback.poses(at: 20)
        #expect(collisionPose5 != nil)
        let collisionCue6 = playback.consumeCollision(at: 20)
        #expect(collisionCue6)
        playback.reset()
        let collisionCue7 = playback.consumeCollision(at: 30)
        #expect(!collisionCue7)
        final = frame(UUID(), sequence: 1, time: 0, x: 1)
        playback.append(final, receivedAt: 30)
        let collisionCue8 = playback.consumeCollision(at: 31)
        #expect(!collisionCue8)
    }

    @Test
    func collisionMarkerIsOptionalAndRejectsInvalidOrFutureTimes() throws {
        var sample = frame(UUID(), sequence: 1, time: 0.5, x: 0)
        let data = try JSONEncoder().encode(sample)
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json.removeValue(forKey: "collisionTimestamp")
        let older = try JSONDecoder().decode(ThrowFrame.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(older.collisionTimestamp == nil)
        #expect(older.isValid)
        for timestamp: TimeInterval in [-1, .nan, .infinity, 0.6] {
            sample.collisionTimestamp = timestamp
            #expect(!sample.isValid)
        }
        sample.collisionTimestamp = 0.2
        #expect(sample.isValid)
        sample.timestamp = nil
        #expect(!sample.isValid)
    }

    @Test
    func interpolatesPositionScaleAndRotationUsingSenderTimeDespiteJitter() throws {
        var playback = RemoteThrowPlayback(delay: 0.1)
        let game = UUID()
        playback.append(frame(game, sequence: 1, time: 0, x: 0), receivedAt: 10)
        playback.append(frame(game, sequence: 2, time: 0.1, x: 1, angle: .pi / 2, scale: 2), receivedAt: 10.14)
        let sampled1 = playback.poses(at: 10.15)
        let halfway = try #require(sampled1?.first)
        #expect(abs(halfway.position.x - 0.5) < 0.0001)
        #expect(abs(halfway.scale.x - 1.5) < 0.0001)
        #expect(abs(simd_quatf(vector: halfway.rotation).angle - .pi / 4) < 0.0001)
        let sampled2 = playback.poses(at: 10.175)
        let advanced = try #require(sampled2?.first)
        #expect(advanced.position.x > halfway.position.x)
        #expect(advanced.position.x < 1)
    }

    @Test
    func lostPacketInterpolatesBetweenAvailableSamplesAndNeverPredictsPastLatest() throws {
        var playback = RemoteThrowPlayback(delay: 0.1)
        let game = UUID()
        playback.append(frame(game, sequence: 1, time: 0, x: 0), receivedAt: 1)
        playback.append(frame(game, sequence: 4, time: 0.3, x: 3), receivedAt: 1.31)
        let sampled3 = playback.poses(at: 1.35)
        #expect(abs(try #require(sampled3?.first).position.x - 2.5) < 0.0001)
        let sampled4 = playback.poses(at: 5)
        #expect(try #require(sampled4?.first).position.x == 3)
        #expect(!playback.reachedFinal)
    }

    @Test
    func finalArrivesWithoutSnappingBufferedMotionAndThenRemainsExact() throws {
        var playback = RemoteThrowPlayback(delay: 0.1)
        let game = UUID()
        playback.append(frame(game, sequence: 1, time: 0, x: 0), receivedAt: 10)
        playback.append(frame(game, sequence: 2, time: 0.1, x: 1, final: true), receivedAt: 10.1)
        let sampled5 = playback.poses(at: 10.15)
        #expect(abs(try #require(sampled5?.first).position.x - 0.5) < 0.0001)
        #expect(!playback.reachedFinal)
        let sampled6 = playback.poses(at: 10.21)
        #expect(try #require(sampled6?.first).position.x == 1)
        #expect(playback.reachedFinal)
        let accepted7 = playback.append(frame(game, sequence: 3, time: 0.2, x: 99), receivedAt: 10.3)
        #expect(!accepted7)
        let sampled8 = playback.poses(at: 11)
        #expect(try #require(sampled8?.first).position.x == 1)
    }

    @Test
    func duplicateReorderedAndRegressingTimeSamplesDoNotRewindPlayback() throws {
        var playback = RemoteThrowPlayback(delay: 0)
        let game = UUID()
        let accepted9 = playback.append(frame(game, sequence: 2, time: 0.2, x: 2), receivedAt: 1)
        #expect(accepted9)
        let accepted10 = playback.append(frame(game, sequence: 1, time: 0.1, x: 1), receivedAt: 1.1)
        #expect(!accepted10)
        let accepted11 = playback.append(frame(game, sequence: 2, time: 0.2, x: 8), receivedAt: 1.2)
        #expect(!accepted11)
        let accepted12 = playback.append(frame(game, sequence: 3, time: 0.1, x: 9), receivedAt: 1.3)
        #expect(!accepted12)
        let sampled13 = playback.poses(at: 2)
        #expect(try #require(sampled13?.first).position.x == 2)
    }

    @Test
    func timestampsRemainOptionalForOlderMessages() throws {
        var old = frame(UUID(), sequence: 1, time: 0, x: 4)
        old.timestamp = nil
        let data = try JSONEncoder().encode(old)
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json.removeValue(forKey: "timestamp")
        let decoded = try JSONDecoder().decode(ThrowFrame.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(decoded.timestamp == nil)
        #expect(decoded.isValid)
        var playback = RemoteThrowPlayback()
        let accepted14 = playback.append(decoded, receivedAt: 10)
        #expect(accepted14)
        let sampled15 = playback.poses(at: 11)
        #expect(try #require(sampled15?.first).position.x == 4)
    }

    @Test
    func resetAndNewThrowDoNotKeepOldFinalOrClockOffset() throws {
        let game = UUID()
        var playback = RemoteThrowPlayback()
        playback.append(frame(game, sequence: 1, time: 100, x: 4, final: true), receivedAt: 1)
        let sampled16 = playback.poses(at: 1)
        #expect(try #require(sampled16?.first).position.x == 4)
        #expect(playback.reachedFinal)
        var next = frame(game, sequence: 1, time: 0, x: 7)
        next = ThrowFrame(gameID: game, throwRevision: 8, poses: next.poses, isFinal: false, sequence: 1, timestamp: 0)
        let accepted17 = playback.append(next, receivedAt: 20)
        #expect(accepted17)
        #expect(!playback.reachedFinal)
        let sampled18 = playback.poses(at: 20)
        #expect(try #require(sampled18?.first).position.x == 7)
        playback.reset()
        let sampled19 = playback.poses(at: 30)
        #expect(sampled19 == nil)
        #expect(playback.lastReceivedAt == nil)
    }

    @Test
    func oppositeQuaternionSignsDoNotCauseFullRotation() throws {
        var playback = RemoteThrowPlayback(delay: 0)
        let game = UUID()
        let a = frame(game, sequence: 1, time: 0, x: 0)
        let b = ThrowFrame(gameID: game, throwRevision: 4,
            poses: a.poses.map { .init(index: $0.index, position: $0.position, rotation: -$0.rotation, scale: $0.scale) },
            isFinal: false, sequence: 2, timestamp: 0.1)
        playback.append(a, receivedAt: 1)
        playback.append(b, receivedAt: 1.1)
        let sampled20 = playback.poses(at: 1.05)
        let pose = try #require(sampled20?.first)
        #expect(abs(simd_quatf(vector: pose.rotation).act([0, 1, 0]).y - 1) < 0.0001)
    }

    @Test
    func invalidSamplesAreRejectedBeforeAffectingTheStream() {
        var playback = RemoteThrowPlayback()
        var sample = frame(UUID(), sequence: 1, time: 0, x: 0)
        sample.timestamp = .infinity
        let accepted21 = playback.append(sample, receivedAt: 1)
        #expect(!accepted21)
        sample.timestamp = 0
        let accepted22 = playback.append(sample, receivedAt: .nan)
        #expect(!accepted22)
        let sampled23 = playback.poses(at: 1)
        #expect(sampled23 == nil)
    }

    private func frame(_ game: UUID, sequence: Int, time: TimeInterval, x: Float,
                       angle: Float = 0, scale: Float = 1, final: Bool = false) -> ThrowFrame {
        ThrowFrame(gameID: game, throwRevision: 4, poses: (0..<4).map {
            .init(index: $0, position: [x, Float($0), 0], rotation: simd_quatf(angle: angle, axis: [0, 1, 0]).vector,
                  scale: SIMD3(repeating: scale))
        }, isFinal: final, sequence: sequence, timestamp: time)
    }
}
