import Foundation

/// 사람의 식별자와 조작 기기의 식별자를 분리해 한 기기에서 여러 플레이어가 참여할 수 있게 한다.
struct GamePlayer: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let order: Int
    /// 같은 기기에 등록한 플레이어들은 이 값을 공유하며, 자기 차례의 입력 권한을 판단할 때 사용한다.
    let deviceID: UUID

    init(id: UUID = UUID(), name: String, order: Int, deviceID: UUID? = nil) {
        self.id = id
        self.name = name
        self.order = order
        self.deviceID = deviceID ?? id
    }
}
