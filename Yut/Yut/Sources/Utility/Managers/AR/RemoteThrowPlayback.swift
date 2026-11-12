import Foundation
import simd

/// 송신 기기의 시각을 로컬 시각에 정렬하고 짧은 지연 버퍼에서 자세를 보간한다.
/// 네트워크가 끊기면 마지막 자세를 유지하며 임의의 물리 궤적을 예측하지 않는다.
struct RemoteThrowPlayback {
    private struct Sample {
        let time: TimeInterval
        let frame: ThrowFrame
    }

    let delay: TimeInterval
    private var samples: [Sample] = []
    private var clockOffset: TimeInterval?
    private var gameID: UUID?
    private var throwRevision: Int?
    private var lastSequence: Int?
    private var hasFinal = false
    private var collisionTimestamp: TimeInterval?
    private var consumedCollision = false
    private(set) var reachedFinal = false
    private(set) var lastReceivedAt: TimeInterval?

    init(delay: TimeInterval = 0.1) { self.delay = max(0, delay) }

    /// 이미 반영한 순번과 최종 자세 뒤의 패킷은 버린다. 새 게임·투사는 별도 재생 구간이다.
    @discardableResult
    mutating func append(_ frame: ThrowFrame, receivedAt: TimeInterval) -> Bool {
        guard frame.isValid, receivedAt.isFinite else { return false }
        if gameID != frame.gameID || throwRevision != frame.throwRevision {
            reset()
            gameID = frame.gameID
            throwRevision = frame.throwRevision
        }
        guard !hasFinal, lastSequence.map({ frame.sequence > $0 }) ?? true else { return false }
        let sourceTime = frame.timestamp ?? (receivedAt - (clockOffset ?? 0))
        guard samples.last.map({ sourceTime >= $0.time }) ?? true else { return false }
        if clockOffset == nil { clockOffset = receivedAt - sourceTime }
        if samples.last?.time == sourceTime { samples.removeLast() }
        samples.append(Sample(time: sourceTime, frame: frame))
        if samples.count > 32 { samples.removeFirst(samples.count - 32) }
        lastSequence = frame.sequence
        lastReceivedAt = receivedAt
        hasFinal = frame.isFinal
        if collisionTimestamp == nil { collisionTimestamp = frame.collisionTimestamp }
        return true
    }

    /// 렌더 프레임 시각에 맞는 위치·크기와 최단 회전 방향의 쿼터니언을 반환한다.
    mutating func poses(at time: TimeInterval) -> [ThrowFrame.Pose]? {
        guard time.isFinite, let clockOffset, let first = samples.first else { return nil }
        let target = time - clockOffset - delay
        if samples.count == 1 && hasFinal {
            reachedFinal = true
            return first.frame.poses
        }
        while samples.count > 1, samples[1].time <= target { samples.removeFirst() }
        guard let left = samples.first else { return nil }
        guard samples.count > 1, target > left.time else {
            reachedFinal = hasFinal && target >= left.time
            return left.frame.poses
        }
        let right = samples[1]
        let fraction = Float(min(max((target - left.time) / (right.time - left.time), 0), 1))
        return left.frame.poses.compactMap { pose in
            guard let next = right.frame.poses.first(where: { $0.index == pose.index }) else { return nil }
            return ThrowFrame.Pose(
                index: pose.index,
                position: pose.position + (next.position - pose.position) * fraction,
                rotation: simd_slerp(simd_quatf(vector: pose.rotation), simd_quatf(vector: next.rotation), fraction).vector,
                scale: pose.scale + (next.scale - pose.scale) * fraction
            )
        }
    }

    mutating func reset() {
        samples = []
        clockOffset = nil
        gameID = nil
        throwRevision = nil
        lastSequence = nil
        hasFinal = false
        collisionTimestamp = nil
        consumedCollision = false
        reachedFinal = false
        lastReceivedAt = nil
    }

    /// 자세와 같은 재생 시각에서 첫 충돌음을 한 번만 꺼낸다. 최종 자세만 수신했다면 표시 시점에 맞춘다.
    mutating func consumeCollision(at time: TimeInterval) -> Bool {
        guard time.isFinite, !consumedCollision, let collisionTimestamp,
              let clockOffset, let last = samples.last else { return false }
        let target = reachedFinal ? last.time : min(time - clockOffset - delay, last.time)
        guard target >= collisionTimestamp else { return false }
        consumedCollision = true
        return true
    }
}
