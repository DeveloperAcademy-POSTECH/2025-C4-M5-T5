import Foundation
import RealityKit
import ARKit
import CoreMotion

final class YutManager {
    
    // MARK: - Properties
    private unowned let coordinator: ARCoordinator
    
    private var arView: ARView? { coordinator.arView }
    private var arState: ARState? { coordinator.arState }
    
    private let motionManager = CMMotionManager()
    private var lastThrowTime = Date(timeIntervalSince1970: 0)
    
    var thrownYuts: [YutModel] = []
    
    // MARK: - Init
    init(coordinator: ARCoordinator) {
        self.coordinator = coordinator
    }
    
    // MARK: - Motion Detection
    
    func startMonitoringMotion() {
        guard motionManager.isDeviceMotionAvailable else {
            print("❌ 디바이스 모션 사용 불가")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.05
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self, let motion = motion else { return }
            
            let acceleration = motion.userAcceleration
            let magnitude = sqrt(acceleration.x * acceleration.x +
                                 acceleration.y * acceleration.y +
                                 acceleration.z * acceleration.z)
            
            let threshold = 1.5
            let cooldown: TimeInterval = 1.0
            
            if magnitude > threshold,
               Date().timeIntervalSince(self.lastThrowTime) > cooldown {
                self.lastThrowTime = Date()
                self.throwYuts()
            }
        }
    }
    
    // MARK: - Yut Throwing
    
    func throwYuts() {
        guard let arView = arView else { return }
        
        let yutNames = ["Yut1", "Yut2", "Yut3", "Yut4_back"]
        let spacing: Float = 0.07
        
        for i in 0..<yutNames.count {
            guard let yut = try? ModelEntity.loadModel(named: yutNames[i]) else { continue }
            
            let yutModel = YutModel(entity: yut, isFrontUp: nil)
            thrownYuts.append(yutModel)
            
            let physMaterial = PhysicsMaterialResource.generate(
                staticFriction: 1.0,
                dynamicFriction: 1.0,
                restitution: 0.0
            )
            
            yut.generateCollisionShapes(recursive: true)
            yut.physicsBody = PhysicsBodyComponent(
                massProperties: .default,
                material: physMaterial,
                mode: .dynamic
            )
            
            guard let camTransform = arView.session.currentFrame?.camera.transform else { return }
            
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -0.3
            translation.columns.3.x = 0.6 + (Float(i) - 1.5) * spacing
            translation.columns.3.y = 0.6
            
            let finalTransform = simd_mul(camTransform, translation)
            yut.transform = Transform(matrix: finalTransform)
            yut.transform.scale = SIMD3<Float>(repeating: 0.1)
            
            let forward = -simd_make_float3(camTransform.columns.2)
            let flatForward = simd_normalize(SIMD3<Float>(forward.x, 0, forward.z))
            let upward = SIMD3<Float>(0, 3, 0)
            let velocity = flatForward * 2.0 + upward
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                yut.components.set(PhysicsMotionComponent(linearVelocity: velocity))
            }
            
            let anchor = AnchorEntity(world: finalTransform)
            anchor.addChild(yut)
            arView.scene.addAnchor(anchor)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.waitUntilAllYutsStopAndEvaluate()
        }
    }
    
    // MARK: - Evaluation
    
    private func waitUntilAllYutsStopAndEvaluate() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            let allStopped = self.thrownYuts.allSatisfy { $0.isSettled }
            if allStopped {
                timer.invalidate()
                self.evaluateYuts()
            }
        }
    }
    
    private func evaluateYuts() {
        for i in 0..<thrownYuts.count {
            let entity = thrownYuts[i].entity
            let frontAxis = SIMD3<Float>(1, 0, 0)
            let worldUp = SIMD3<Float>(0, 1, 0)
            let rotated = entity.transform.rotation.act(frontAxis)
            let dot = simd_dot(rotated, worldUp)
            let isFront = dot > 0
            thrownYuts[i].isFrontUp = isFront
        }
        
        let frontCount = thrownYuts.filter { $0.isFrontUp == true }.count
        let backYut = thrownYuts.first(where: {
            $0.entity.name == "Yut4_back" && $0.isFrontUp == false
        })
        
        let result: YutResult
        if frontCount == 3, backYut != nil {
            result = .backdho
        } else {
            switch frontCount {
            case 0: result = .mo
            case 1: result = .dho
            case 2: result = .gae
            case 3: result = .geol
            case 4: result = .yut
            default:
                print("⚠️ 유효하지 않은 윷 결과")
                return
            }
        }
        
        print("🎯 윷 결과: \(result) (\(result.steps)칸 이동)")
        if result.isExtraTurn {
            print("🎁 추가 턴!")
        }
    }
}
