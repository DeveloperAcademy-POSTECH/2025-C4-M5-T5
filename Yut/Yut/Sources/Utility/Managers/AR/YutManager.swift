import ARKit
import Combine
import CoreMotion
import CoreHaptics
import Foundation
import RealityKit

@MainActor
final class YutManager {
    // MARK: - Properties
    private unowned let coordinator: ARCoordinator
    
    private var arView: ARView? { coordinator.arView }
    private var arState: ARState? { coordinator.arState }
    private let yutNames = ["Yut1", "Yut2", "Yut3", "Yut4_back"]
    private let haptics = HapticsService()
    private let sound: any GameSoundPlaying
    private var didPlaySoundForCurrentThrow = false
    private var collisionSubscription: Cancellable?
    
    private var preloadedModels: [String: ModelEntity] = [:]
    private let motionManager = CMMotionManager()
    private var lastThrowTime = Date(timeIntervalSince1970: 0)
    
    var thrownYuts: [YutModel] = []
    private var throwTask: Task<Void, Never>?
    private var evaluationTimer: Timer?
    private var generation = UUID()
    var isMotionAvailable: Bool { motionManager.isDeviceMotionAvailable }

    /// 중단된 투사의 비동기 생성·평가·센서 작업만 취소한다. 투사 수치와 정상 판정 조건은 유지한다.
    func stop() {
        generation = UUID()
        motionManager.stopDeviceMotionUpdates()
        throwTask?.cancel()
        throwTask = nil
        evaluationTimer?.invalidate()
        evaluationTimer = nil
        collisionSubscription = nil
        haptics.stop()
        for model in thrownYuts { model.entity.parent?.removeFromParent() }
        thrownYuts = []
    }

    func throwManually() {
        guard coordinator.beginLocalThrow() else { return }
        arState?.showFinalFrame = false
        subscribeToYutCollisions()
        throwYuts()
    }
    
    // MARK: - Init
    init(coordinator: ARCoordinator, sound: any GameSoundPlaying) {
        self.coordinator = coordinator
        self.sound = sound
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
            
            guard impulse >= 0.4 else {
                // print("⚠️ 너무 약한 충돌 무시됨: \(impulse)")
                return
            }
            
            let normalized = min(impulse / 5.0, 1.0)
            let collisionGeneration = self.generation
            Task { @MainActor in
                guard self.generation == collisionGeneration else { return }
                self.haptics.playCollisionHaptic(with: normalized, sharpness: normalized)
                
                if !self.didPlaySoundForCurrentThrow,
                       (aIsYut && bIsFloor) || (bIsYut && aIsFloor) {
                        self.sound.playCollisionSound()
                        self.didPlaySoundForCurrentThrow = true
                        self.coordinator.didPlayLocalCollisionSound()
                    }
            }
        }
    }
    
    // MARK: - Motion Detection
    
    func startMonitoringMotion() {
        guard !motionManager.isDeviceMotionActive else { return }
        guard self.motionManager.isDeviceMotionAvailable else { self.coordinator.motionFailed(); return }
        self.arState?.showFinalFrame = true
        self.motionManager.deviceMotionUpdateInterval = 0.05
        self.motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            MainActor.assumeIsolated {
                guard let self else { return }
                if error != nil { self.motionManager.stopDeviceMotionUpdates(); self.coordinator.motionFailed(); return }
                guard let motion else { return }
                let acceleration = motion.userAcceleration
                let magnitude = sqrt(acceleration.x * acceleration.x + acceleration.y * acceleration.y + acceleration.z * acceleration.z)
                let threshold = 1.5
                let cooldown: TimeInterval = 1.0
                if magnitude > threshold, Date().timeIntervalSince(self.lastThrowTime) > cooldown {
                    guard self.coordinator.beginLocalThrow() else { return }
                    self.arState?.showFinalFrame = false
                    self.lastThrowTime = Date()
                    self.subscribeToYutCollisions()
                    self.throwYuts()
                    self.motionManager.stopDeviceMotionUpdates()
                }
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
        let expectedGeneration = generation
        throwTask = Task { @MainActor in
            for i in 0..<yutNames.count {
                guard !Task.isCancelled, generation == expectedGeneration else { return }
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
                        guard !Task.isCancelled, generation == expectedGeneration else { return }
                        yut.components.set(CollisionComponent(shapes: [shape]))
                    } catch is CancellationError {
                        return
                    } catch {
                        guard !Task.isCancelled, generation == expectedGeneration else { return }
                        yut.generateCollisionShapes(recursive: true)
                    }
                }
                
                guard !Task.isCancelled, generation == expectedGeneration else { return }
                yut.physicsBody = PhysicsBodyComponent(
                    massProperties: .init(mass: 5),
                    material: physMaterial,
                    mode: .dynamic
                )
                
                // 5. 위치 계산
#if targetEnvironment(simulator)
                let camTransform = arView.cameraTransform.matrix
#else
                guard let camTransform = arView.session.currentFrame?.camera.transform else { return }
#endif
                
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
                    guard self.generation == expectedGeneration else { return }
                    yut.components.set(PhysicsMotionComponent(linearVelocity: velocity))
                }
                
                // 7. 엔티티 추가
                yut.components.set(InputTargetComponent())
                let anchor = AnchorEntity(world: finalTransform)
#if targetEnvironment(simulator)
                anchor.anchoring.physicsSimulation = .none
#endif
                anchor.addChild(yut)
                arView.scene.addAnchor(anchor)
            }
            
            // 8. 평가 대기 타이머
            do { try await Task.sleep(nanoseconds: 1_000_000_000) } catch { return }
            guard generation == expectedGeneration, !Task.isCancelled else { return }
            self.waitUntilAllYutsStopAndEvaluate()
            
        }
    }
    
    // MARK: - Evaluation
    private func waitUntilAllYutsStopAndEvaluate() {
        let expectedGeneration = generation
        evaluationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
            guard let self = self else {
                timer.invalidate()
                return
            }

            guard self.generation == expectedGeneration else { timer.invalidate(); return }
            let yutThreshold: Float = -50.0
            var hasFallenYut = false

            // relativeTo: nil → 월드 기준
            for yut in self.thrownYuts {
//                print(yut.entity.position(relativeTo: nil).y)
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
                self.coordinator.yutThrowCompleted(with: .nak)
                return
            }

            let allStopped = self.thrownYuts.count == 4 && self.thrownYuts.allSatisfy { $0.isSettled }
            if allStopped {
                timer.invalidate()
                self.evaluateYuts()
            }
            }
        }
    }
    
    /// 모델의 둥근 면(로컬 +Y)을 부모 앵커 회전까지 포함한 월드 위쪽과 비교한다.
    /// 기존 isFrontUp은 둥근 면이 위인 상태로 사용해, 0개면 윷·4개면 모인 결과 계산을 유지한다.
    func evaluateYuts() {
        for i in 0..<thrownYuts.count {
            let entity = thrownYuts[i].entity
            let roundedSideAxis = SIMD3<Float>(0, 1, 0)
            let worldUp = SIMD3<Float>(0, 1, 0)
            let rotated = entity.orientation(relativeTo: nil).act(roundedSideAxis)
            let dot = simd_dot(rotated, worldUp)
            let isFront = dot > 0
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
