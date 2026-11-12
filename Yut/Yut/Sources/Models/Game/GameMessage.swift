import Foundation
import simd

struct SharedBoard: Codable, Equatable, Sendable {
    let anchorID: UUID
    let worldMap: Data
    let scale: Float
}

/// 투사 기기에서 계산한 시각 자세만 전달한다. 수신 기기에서 별도의 물리 던지기를 실행하지 않는다.
struct ThrowFrame: Codable, Equatable, Sendable {
    struct Pose: Codable, Equatable, Sendable {
        let index: Int
        let position: SIMD3<Float>
        let rotation: SIMD4<Float>
        let scale: SIMD3<Float>

        var isValid: Bool {
            (0..<4).contains(index) && position.indices.allSatisfy { position[$0].isFinite }
                && rotation.indices.allSatisfy { rotation[$0].isFinite }
                && abs(simd_length(rotation) - 1) < 0.001
                && scale.indices.allSatisfy { scale[$0].isFinite && scale[$0] > 0 }
        }
    }

    let gameID: UUID
    let throwRevision: Int
    let poses: [Pose]
    let isFinal: Bool
    var sequence = 0
    /// 투사 시작 기준 단조 시각. 이전 형식의 메시지는 수신 시각으로 재생한다.
    var timestamp: TimeInterval? = nil
    /// 첫 유효 바닥 충돌 시각. 같은 투사의 후속 자세·신뢰 전송 최종 프레임에도 유지한다.
    var collisionTimestamp: TimeInterval? = nil

    var isValid: Bool {
        guard sequence >= 0, timestamp.map({ $0.isFinite && $0 >= 0 }) ?? true,
              poses.count == 4, Set(poses.map(\.index)).count == 4, poses.allSatisfy(\.isValid) else { return false }
        guard let collisionTimestamp else { return true }
        return collisionTimestamp.isFinite && collisionTimestamp >= 0
            && timestamp.map { collisionTimestamp <= $0 } == true
    }
}

enum GameMessage: Codable, Equatable, Sendable {
    case startGame(GameState)
    case state(GameState)
    case request(GameRequest)
    case requestRematch
    case requestSynchronization
    case board(gameID: UUID, SharedBoard)
    case collaboration(gameID: UUID, data: Data, isCritical: Bool)
    case throwFrame(ThrowFrame)
}
