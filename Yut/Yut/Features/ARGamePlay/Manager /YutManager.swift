import Foundation
import RealityKit
import ARKit
import CoreMotion

final class YutManager {
    
    // MARK: - Properties
    private unowned let coordinator: ARCoordinator
    
    private var arView: ARView? { coordinator.arView }
    private var arState: ARState? { coordinator.arState }
    
    private var preloadedModels: [String: ModelEntity] = [:]
    private let motionManager = CMMotionManager()
    private var lastThrowTime = Date(timeIntervalSince1970: 0)
    
    var thrownYuts: [YutModel] = []
    
    // MARK: - Init
    init(coordinator: ARCoordinator) {
        self.coordinator = coordinator
    }
    
    func preloadYutModels() {
        let yutNames = ["Yut1", "Yut2", "Yut3", "Yut4_back"]
        
        for name in yutNames {
            // 이미 로드되어 있다면 건너뜀
            if preloadedModels[name] != nil { continue }
            
            do {
                let model = try ModelEntity.loadModel(named: name)
                preloadedModels[name] = model
            } catch {
                print("⚠️ \(name) 미리 로딩 실패: \(error)")
            }
        }
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
        // 기존 윷 제거
            
            // 1. 씬(Scene)에서 이전에 던져진 윷 엔티티들을 제거합니다.
            for yutModel in thrownYuts {
                // 각 윷(ModelEntity)은 AnchorEntity의 자식으로 추가되었으므로,
                // 부모 앵커를 찾아서 씬에서 제거해야 합니다.
                yutModel.entity.parent?.removeFromParent()
            }
            
            // 2. 다음 계산을 위해 윷 모델을 추적하는 배열을 비웁니다.
            thrownYuts.removeAll()
        
        let yutNames = ["Yut1", "Yut2", "Yut3", "Yut4_back"]
        let spacing: Float = 0.01
        
        for i in 0..<4 {
            guard let original = preloadedModels[yutNames[i]] else {
                print("❌ 사전 로딩되지 않은 모델: \(yutNames[i])")
                continue
            }
            
            let yut = original.clone(recursive: true)
            
            let yutModel = YutModel(entity: yut, isFrontUp: nil)
            thrownYuts.append(yutModel)
            
            
//            guard let yut = try? ModelEntity.loadModel(named: yutNames[i]) else { continue }
//            let yutModel = YutModel(entity: yut, isFrontUp: nil)
//            thrownYuts.append(yutModel)
//            
            let physMaterial = PhysicsMaterialResource.generate(
                staticFriction: 1.0,
                dynamicFriction: 1.0,
                restitution: 0.0
            )
            
            Task { @MainActor in
                 guard let modelComponent = yut.components[ModelComponent.self] else {
                     print("❌ ModelComponent 없음")
                     yut.generateCollisionShapes(recursive: true) // fallback
                     return
                 }

                 do {
                     let shape = try await ShapeResource.generateConvex(from: modelComponent.mesh)
                     yut.components.set(CollisionComponent(shapes: [shape]))
                 } catch {
                     print("⚠️ Convex shape 생성 실패: \(error)")
                     yut.generateCollisionShapes(recursive: true) // fallback
                 }
             }
            
            yut.physicsBody = PhysicsBodyComponent(
                massProperties: .init(mass: 10),
                material: physMaterial,
                mode: .dynamic
            )
            
            
            
            guard let camTransform = arView.session.currentFrame?.camera.transform else { return }
            
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -0.1
            //            translation.columns.3.x = 0.6
            //            translation.columns.3.y = 0.3
            translation.columns.3.y += (Float(i) - 0.5) * spacing  // 앞뒤 퍼짐
            
            let finalTransform = simd_mul(camTransform, translation)
//            yut.transform = Transform(matrix: finalTransform)
            
            let rotation = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 0, 1))  // 세로 회전

            let baseTransform = Transform(matrix: finalTransform)
            yut.transform = Transform(
                rotation: rotation * baseTransform.rotation, // ← 여기 적용 중요
            )
            
            let forward = -simd_make_float3(camTransform.columns.2)
            let flatForward = simd_normalize(SIMD3<Float>(forward.x, 0, forward.z))
            let upward = SIMD3<Float>(0, 3, 0)
            let velocity = flatForward * 1.0 + upward
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                yut.components.set(PhysicsMotionComponent(linearVelocity: velocity))
            }
            
//            let x = ModelEntity(mesh: .generateBox(size: 0.02), materials: [SimpleMaterial(color: .red, isMetallic: false)])
//             x.position = SIMD3<Float>(0.1, 0, 0)  // X축
//
//             let y = ModelEntity(mesh: .generateBox(size: 0.02), materials: [SimpleMaterial(color: .green, isMetallic: false)])
//             y.position = SIMD3<Float>(0, 0.1, 0)  // Y축
//
//             let z = ModelEntity(mesh: .generateBox(size: 0.02), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
//             z.position = SIMD3<Float>(0, 0, 0.1)  // Z축
//
//             yut.addChild(x)
//             yut.addChild(y)
//             yut.addChild(z)
            
            
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
    
    func evaluateYuts() {
        // 앞뒤 판단 먼저 수행
        for i in 0..<thrownYuts.count {
            let entity = thrownYuts[i].entity
//            let up = entity.transform.rotation.act(SIMD3<Float>(0, 1, 0))
//            let dot = simd_dot(up, SIMD3<Float>(0, 1, 0))
//            let isFront = dot >= 0
            
//            let upVector = entity.transform.rotation.act(SIMD3<Float>(0, 1, 0))
//            let isFront = upVector.y > 0.5
            
            let frontAxis = SIMD3<Float>(0, 1, 0) // 모델링에서 앞면이 향한 축으로 변경 필요
            let worldUp = SIMD3<Float>(1, 0, 0)
            
            let rotated = entity.transform.rotation.act(frontAxis)
            let dot = simd_dot(rotated, worldUp)
            let isFront = dot < 0
            
            thrownYuts[i].isFrontUp = isFront
            
            print("rotated: \(rotated)")
            print("dot: \(dot)")
            
            thrownYuts[i].isFrontUp = isFront
            print("윷 \(entity.name) → 앞면: \(isFront)")
        }
        
        // 백도 예외 케이스 확인
        let frontCount = thrownYuts.filter { $0.isFrontUp == true }.count
        let backYut = thrownYuts.first(where: {
            $0.entity.name == "Yut_4_back" && $0.isFrontUp == false
        })
        
        let result: YutResult
        if frontCount == 3, backYut != nil {
            result = .backdho
        } else {
            switch frontCount {
            case 0: result = .yut
            case 1: result = .geol
            case 2: result = .gae
            case 3: result = .dho
            case 4: result = .mo
            default:
                print("⚠️ 유효하지 않은 윷 결과 - 다시 던지기")
                return
            }
        }

        print("🎯 윷 결과: \(result) (\(result.steps)칸 이동)")
        if result.isExtraTurn {
            print("🎁 추가 턴!")
        }
        
        DispatchQueue.main.async {
            print("[DEBUG] Setting to .showingYutResult")
            self.arState?.yutResult = result
            self.arState?.gamePhase = .showingYutResult
        }
        
        // Coordinator 연결
        coordinator.yutThrowCompleted(with: result)
    }
    
//    private func evaluateYuts() {
//        for i in 0..<thrownYuts.count {
//            let entity = thrownYuts[i].entity
//            let frontAxis = SIMD3<Float>(1, 0, 0)
//            let worldUp = SIMD3<Float>(1, 0, 0)
//            let rotated = entity.transform.rotation.act(frontAxis)
//            let dot = simd_dot(rotated, worldUp)
//            let isFront = dot > 0
//            thrownYuts[i].isFrontUp = isFront
//        }
//        
//        let frontCount = thrownYuts.filter { $0.isFrontUp == true }.count
//        let backYut = thrownYuts.first(where: {
//            $0.entity.name == "Yut4_back" && $0.isFrontUp == false
//        })
//        
//        let result: YutResult
//        if frontCount == 3, backYut != nil {
//            result = .backdho
//        } else {
//            switch frontCount {
//            case 0: result = .mo      // 모두 뒷면 → 모
//            case 1: result = .dho     // 도
//            case 2: result = .gae     // 개
//            case 3: result = .geol    // 걸
//            case 4: result = .yut     // 모두 앞면 → 윷
//            default:
//                print("⚠️ 유효하지 않은 윷 결과")
//                return
//            }
//        }
//        
//        print("🎯 윷 결과: \(result) (\(result.steps)칸 이동)")
//        if result.isExtraTurn {
//            print("🎁 추가 턴!")
//        }
//    }
}

