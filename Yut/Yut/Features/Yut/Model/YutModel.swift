import RealityKit
import Foundation

struct YutModel {
    let id: UUID = UUID()     // 식별용
    let entity: ModelEntity   // 실제 RealityKit 상의 윷
    var isFrontUp: Bool?      // 결과 판단 후 저장
}
