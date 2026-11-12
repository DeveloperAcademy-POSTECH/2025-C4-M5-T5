import Foundation

/// 대기실 명단은 RealityKit 엔티티와 분리해 전송한다. 같은 UUID는 수신 측의 기존 객체를 재사용한다.
struct LobbyPlayerSnapshot: Codable {
    let id: UUID
    let name: String
    let sequence: Int
    let peerData: Data
    let isHost: Bool
    let deviceID: UUID
}

/// 명단·시작은 호스트가 확정하고, 참가자는 자신의 추가 인원만 요청한다.
enum LobbyMessage: Codable {
    case hello(UUID)
    case players([LobbyPlayerSnapshot])
    case addPlayer(String)
    case startGame(UUID)
    case roomClosed
    case game(GameMessage)
}
