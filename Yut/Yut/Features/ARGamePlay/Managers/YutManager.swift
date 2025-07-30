import Foundation
import RealityKit
import ARKit
import CoreMotion
import CoreHaptics
import Combine

final class YutManager {
    
    // MARK: - Properties
    private unowned let coordinator: ARCoordinator
    
    private var arView: ARView? { coordinator.arView }
    private var arState: ARState? { coordinator.arState }
    private let yutNames = ["Yut1", "Yut2", "Yut3", "Yut4_back"]
    private let haptics = HapticsService()
    private let sound = SoundService()
    private var didPlaySoundForCurrentThrow = false
    private var collisionSubscription: Cancellable?
    
    private var preloadedModels: [String: ModelEntity] = [:]
    private let motionManager = CMMotionManager()
    private var lastThrowTime = Date(timeIntervalSince1970: 0)
    
    var thrownYuts: [YutModel] = []
    
    // MARK: - Init
    init(coordinator: ARCoordinator) {
        self.coordinator = coordinator
        
    }
    
    // MARK: - Preload
    func preloadYutModels() {
        for name in yutNames {
            if preloadedModels[name] != nil { continue }
            do {
                let model = try ModelEntity.loadModel(named: name)
                preloadedModels[name] = model
            } catch {
                //                print("\u26a0\ufe0f \(name) 미리 로딩 실패: \(error)")
            }
        }
    }
    
    // MARK: - 햅틱
    
    func subscribeToYutCollisions() {
        guard let scene = arView?.scene else { return }
        
        let yutPrefix = "Yut_"
        let floorNames: Set<String> = ["YutBoardCollision", "Plane"]
        
        collisionSubscription = scene.subscribe(to: CollisionEvents.Began.self) { [weak self] event in
            guard let self = self else { return }
            guard let a = event.entityA as? ModelEntity,
                  let b = event.entityB as? ModelEntity else {
//                print("❌ 캐스팅 실패: \(event)")
                return
            }
            
            let aIsYut = a.name.hasPrefix(yutPrefix)
            let bIsYut = b.name.hasPrefix(yutPrefix)
            let aIsFloor = floorNames.contains(a.name)
            let bIsFloor = floorNames.contains(b.name)
            
            // 윷끼리 또는 윷+바닥 충돌일 경우에만 통과
            guard (aIsYut && bIsYut) || (aIsYut && bIsFloor) || (bIsYut && aIsFloor) else {
//                print("❌ 충돌 무시: \(a.name) vs \(b.name)")
                return
            }
            
//            print("💥 충돌 감지: \(a.name) & \(b.name), impulse: \(event.impulse)")

            let impulse = event.impulse
            
            // 1. 너무 약한 충돌은 무시 (여기서 걸러냄)
            guard impulse >= 0.4 else {
                // print("⚠️ 너무 약한 충돌 무시됨: \(impulse)")
                return
            }
            
            // 2. 강도 비례 정규화 (최솟값 제한 없음)
            let normalized = min(impulse / 5.0, 1.0)
            Task { @MainActor in
                self.haptics.playCollisionHaptic(with: normalized, sharpness: normalized)
                
                if !self.didPlaySoundForCurrentThrow,
                       (aIsYut && bIsFloor) || (bIsYut && aIsFloor) {
                        self.sound.playCollisionSound()
                        self.didPlaySoundForCurrentThrow = true
                    }
            }
        }
    }
    
    // MARK: - Motion Detection
    
    func startMonitoringMotion() {
        guard motionManager.isDeviceMotionAvailable else {
            return
        }

        self.arState?.showFinalFrame = true

        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion = motion else { return }
            
            let acceleration = motion.userAcceleration
            let magnitude = sqrt(acceleration.x * acceleration.x +
                                 acceleration.y * acceleration.y +
                                 acceleration.z * acceleration.z)
            
            let threshold = 1.5
            let cooldown: TimeInterval = 1.0
            
            if magnitude > threshold,
               Date().timeIntervalSince(self.lastThrowTime) > cooldown {
                DispatchQueue.main.async {
                    self.arState?.showFinalFrame = false
                }
                
                self.lastThrowTime = Date()
                subscribeToYutCollisions()
                
                self.throwYuts()
                
                self.motionManager.stopDeviceMotionUpdates() // 윷 던지기 이후 모션 감지 종료
            }
        }
    }
    
    
    
    // MARK: - Yut Throwing
    func throwYuts() {
        guard let arView = arView else { return }
        
        didPlaySoundForCurrentThrow = false
        
//        for yutModel in thrownYuts {
//            yutModel.entity.parent?.removeFromParent()
//        }
//        thrownYuts.removeAll()
        
        let spacing: Float = 0.01
        
        // 2. Task에서 비동기 처리
        Task { @MainActor in
            for i in 0..<yutNames.count {
                
                // AssetCacheManager에서 비동기 로드
                guard let original = coordinator.assetCacheManager.cachedModel(named: yutNames[i]) else {
                    print("❌ 캐시된 모델 없음: \(yutNames[i])")
                    continue
                }
                let yut = original.clone(recursive: true)
                
                let yutModel = YutModel(entity: yut, isFrontUp: nil)
                thrownYuts.append(yutModel)
                
                // 3. 물리 설정
                let physMaterial = PhysicsMaterialResource.generate(
                    staticFriction: 1.0,
                    dynamicFriction: 1.0,
                    restitution: 0.0
                )
                
                // 4. 충돌면 설정
                if let modelComponent = yut.components[ModelComponent.self] {
                    do {
                        let shape = try await ShapeResource.generateConvex(from: modelComponent.mesh)
                        yut.components.set(CollisionComponent(shapes: [shape]))
                    } catch {
                        yut.generateCollisionShapes(recursive: true)
                    }
                }
                
                yut.physicsBody = PhysicsBodyComponent(
                    massProperties: .init(mass: 5),
                    material: physMaterial,
                    mode: .dynamic
                )
                
                // 5. 위치 계산
                guard let camTransform = arView.session.currentFrame?.camera.transform else { return }
                
                var translation = matrix_identity_float4x4
                translation.columns.3.z = -0.1
                translation.columns.3.y += (Float(i) - 0.5) * spacing
                let finalTransform = simd_mul(camTransform, translation)
                
                let rotation = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 0, 1))
                let baseTransform = Transform(matrix: finalTransform)
                yut.transform = Transform(rotation: rotation * baseTransform.rotation)
                
                // 6. 힘 적용
                let forward = -simd_make_float3(camTransform.columns.2)
                let flatForward = simd_normalize(SIMD3<Float>(forward.x, 0, forward.z))
                let upward = SIMD3<Float>(0, 3, 0)
                let velocity = flatForward * 1.0 + upward
                
                // 약간의 딜레이 후 힘 적용
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    yut.components.set(PhysicsMotionComponent(linearVelocity: velocity))
                }
                
                // 7. 엔티티 추가
                yut.components.set(InputTargetComponent())
                let anchor = AnchorEntity(world: finalTransform)
                anchor.addChild(yut)
                arView.scene.addAnchor(anchor)
            }
            
            // 8. 평가 대기 타이머
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            self.waitUntilAllYutsStopAndEvaluate()
            
        }
    }
    
    // MARK: - Evaluation
    private func waitUntilAllYutsStopAndEvaluate() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            let yutThreshold: Float = -50.0
            var hasFallenYut = false

            // relativeTo: nil → 월드 기준
            for yut in self.thrownYuts {
                print(yut.entity.position(relativeTo: nil).y)
                let y = yut.entity.position(relativeTo: nil).y
                if y < yutThreshold {
                    hasFallenYut = true
                    break
                }
            }

            if hasFallenYut {
                timer.invalidate()
                
                print("⚠️ 바닥 밑으로 떨어진 윷 발견 - 다시 던지기")
                self.motionManager.stopDeviceMotionUpdates()
                self.arState?.yutResult = .nak
                
                DispatchQueue.main.async {
                    self.arState?.gamePhase = .showingYutResult
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        // 던져진 윷 제거
                        for yutModel in self.thrownYuts {
                            yutModel.entity.parent?.removeFromParent()
                        }
                        self.thrownYuts.removeAll()
                        
                        self.arState?.gamePhase = .readyToThrow
                    }
                }
                return
            }

            let allStopped = self.thrownYuts.allSatisfy { $0.isSettled }
            if allStopped {
                timer.invalidate()
                self.evaluateYuts()
            }
        }
    }
    
    func evaluateYuts() {
        for i in 0..<thrownYuts.count {
            let entity = thrownYuts[i].entity
            let frontAxis = SIMD3<Float>(0, 1, 0)
            let worldUp = SIMD3<Float>(1, 0, 0)
            let rotated = entity.transform.rotation.act(frontAxis)
            let dot = simd_dot(rotated, worldUp)
            let isFront = dot < 0
            thrownYuts[i].isFrontUp = isFront
        }
        
        let frontCount = thrownYuts.filter { $0.isFrontUp == true }.count
        let backYut = thrownYuts.first(where: { $0.entity.name == "Yut_4_back" && $0.isFrontUp == false })
        
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
                print("⚠️ 유효하지 않은 윷 결과")
                return
            }
        }
        
        Task { @MainActor in
            self.arState?.yutResult = result
            
        }
        
        coordinator.yutThrowCompleted(with: result)
    }
}
