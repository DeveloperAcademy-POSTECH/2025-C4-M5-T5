import RealityKit
import Foundation

struct YutModel {
    let entity: ModelEntity
    var isFrontUp: Bool? = nil
    
    var isSettled: Bool {
        guard let motion = entity.components[PhysicsMotionComponent.self] else { return false }
        return length(motion.linearVelocity) < 0.001 && length(motion.angularVelocity) < 0.001
    }
}

