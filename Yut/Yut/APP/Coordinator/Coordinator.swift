//
//  Coordinator.swift
//  Yut
//
//  Created by yunsly on 7/17/25.
//

import ARKit
import RealityKit
import SwiftUI
import simd
import Combine
import CoreMotion

// ARView의 이벤트의 처리하고 SwiftUI와 연결
class Coordinator: NSObject, ARSessionDelegate {
    weak var arView: ARView?    // 순환 참조 방지 : 소유X 필요할 때만 잠깐 참조
    
    // CoreMotion 센서 매니저
    private let motionManager = CMMotionManager()
    // 너무 자주 던지지 않도록 타이머 제한
    private var lastThrowTime = Date(timeIntervalSince1970: 0)
    
    // 사용자가 조작할 윷판 앵커와 시각화된 평면들을 관리
    var yutBoardAnchor: AnchorEntity?
    var planeEntities: [UUID: ModelEntity] = [:]
    
    // 환경 세팅 시 최소 요구 면적 (15㎡ - 일단은 5로 ... )
    let minRequiredArea: Float = 5
    
    // 제스쳐 조절 변수
    var initialBoardScale: SIMD3<Float>?    // 크기 조정: 핀치 제스처 초기 스케일 저장
    var panOffset: SIMD3<Float>?            // 위치 조절: 팬 제스처 오프셋 변수ㅊ
    var initialBoardRotation: simd_quatf?   // 각도 조절: 회전 제스처를 위한 변수
    
    // 윷 관련 변수
    var yutEntities: [Entity] = []
    var yutHoldingAnchor: AnchorEntity?
    private var yutThrowingForce: Float?    // 윷 던지는 힘 저장
    
    // MARK: - Combine 세팅
    
    // ActionStream 구독을 저장할 변수 (여러 개의 구독을 한꺼번에 관리)
    private var cancellables = Set<AnyCancellable>()
    
    var arState: ARState? {
        didSet {
            subscribeToActionStream()
        }
    }
    
    // ARState 의 actionStream 구독 -> 명령 처리
    private func subscribeToActionStream() {
        guard let arState = arState else { return }
        
        arState.actionStream
            .sink { [weak self] action in       // 메모리 누수 방지
                switch action {
                case .fixBoardPosition:
                    self?.fixBoardPosition()
                case .disablePlaneVisualization:
                    self?.disablePlaneVisualization()
                case .createYuts:
                    self?.createYuts()
                case .startMonitoringMotion:
                    self?.startMonitoringMotion()
                }
            
            }
            .store(in: &cancellables)           // 구독 관리
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            // 1. 앵커카 평면 앵커라면 시각화 모델 생성
            if let planeAnchor = anchor as? ARPlaneAnchor {
                var planeMesh: MeshResource
                do {
                    let vertices = planeAnchor.geometry.vertices.map { SIMD3<Float>($0) }
                    let faceIndices = planeAnchor.geometry.triangleIndices
                    
                    // 가져온 정보들로 직접 메시 구성 정보 설정
                    var descriptor = MeshDescriptor()
                    descriptor.positions = MeshBuffers.Positions(vertices)
                    descriptor.primitives = .triangles(faceIndices.map { UInt32($0)})
                    planeMesh = try .generate(from: [descriptor])
                    
                } catch {
                    print("평면 앵커용 메시 생성 오류: \(error)")
                    continue
                }
                
                let planeMaterial = SimpleMaterial(color: .green.withAlphaComponent(0.2), isMetallic: false)
                let planeEntity = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
                
                // 충돌 감지 및 물리 엔진 상의 정적 오브젝트로 설정
                planeEntity.generateCollisionShapes(recursive: false)   // 하위 엔티티까지는 별개로 설정
                planeEntity.components.set(PhysicsBodyComponent(mode: .static))
                
                // 앵커 생성 후 평면 붙이기
                let anchorEntity = AnchorEntity(anchor: planeAnchor)
                anchorEntity.addChild(planeEntity)
                
                arView?.scene.addAnchor(anchorEntity)                   // 씬에 앵커 추가 -> 화면에 보임
                planeEntities[planeAnchor.identifier] = planeEntity     // 평면 - 식별자로 저장

            }
            // 2. 윷판 배치할 앵커라면 판 배치
            else if let anchorName = anchor.name, anchorName == "YutBoardAnchor" {
                placeYutBoard(on: anchor)
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        var recognizedArea: Float = 0.0      // 인식된 면적의 총 합
        
        // 업데이트 된 앵커들의 시각적/물리적 메시 갱신
        for anchor in anchors {
            // 이전에 저장된 앵커인지 확인
            guard let planeAnchor = anchor as? ARPlaneAnchor,
                  let planeEntity = planeEntities[planeAnchor.identifier] else { continue }
            
            var updatedMesh: MeshResource
            do {
                let vertices = planeAnchor.geometry.vertices.map { SIMD3<Float>($0) }
                let faceIndices = planeAnchor.geometry.triangleIndices
                var descriptor = MeshDescriptor()
                descriptor.positions = MeshBuffers.Positions(vertices)
                descriptor.primitives = .triangles(faceIndices.map { UInt32($0) })
                updatedMesh = try .generate(from: [descriptor])
            } catch {
                print("평면 앵커용 메시 업데이트 오류: \(error)")
                continue
            }
            
            planeEntity.model?.mesh = updatedMesh                       // 시각적 갱신
            planeEntity.generateCollisionShapes(recursive: false)       // 물리 엔진 상호작용
            
            recognizedArea += planeAnchor.meshArea
            
        }
        
        print("인식된 평면의 실제 면적: \(recognizedArea)㎡")
        
        // 전체 면적이 최소 요구 면적을 넘으면 상태 변경
        if arState?.currentState == .searchingForSurface && recognizedArea >= minRequiredArea {
            DispatchQueue.main.async {
                self.arState?.currentState = .completedSearching
            }
        }
    }
    
    // MARK: - Gesture Handlers

    // 화면 탭했을 때 호출
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        
        // 윷판을 배치하는 상태인지 확인
        guard let arView = self.arView,
              arState?.currentState == .placeBoard,
              self.yutBoardAnchor == nil else { return }
        
        let tapLocation = recognizer.location(in: arView)
        let results = arView.raycast(from: tapLocation, allowing: .existingPlaneGeometry, alignment: .horizontal)
        
        // raycast 결과 가장 먼저 맞닿는 평면에 앵커 찍기
        if let firstResult = results.first {
            let anchor = ARAnchor(name: "YutBoardAnchor", transform: firstResult.worldTransform)
            arView.session.add(anchor: anchor)      // didAdd 델리게이트 호출됨
        }
    }
    
    // 크기 조절 제스처: 줌인 줌아웃 할 때 호출
    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        
        // 윷판을 조정하는 상태인지 확인
        guard arState?.currentState == .adjustingBoard,
              let boardAnchor = yutBoardAnchor else { return }
        
        switch recognizer.state {
        case .began:    // 제스쳐 시작: 현재 크기 저장
            initialBoardScale = boardAnchor.scale
        case .changed:  // 제스쳐 중: 초기 크기 * 제스쳐 스케일
            if let initialScae = initialBoardScale {
                boardAnchor.scale = initialScae * Float(recognizer.scale)
            }
        default:        // 제스쳐 종료: 초기화
            initialBoardScale = nil
        }
    }
    
    // 위치 조절 제스쳐: 드래그 할 때 호출
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let arView = self.arView,
              arState?.currentState == .adjustingBoard,
              let boardAnchor = yutBoardAnchor else { return }
        
        // 수평면 위의 3D 좌표 얻기
        let panLocaton = recognizer.location(in: arView)
        guard let result = arView.raycast(from: panLocaton, allowing: .existingPlaneGeometry, alignment: .horizontal).first else { return }
        let hitPosition = Transform(matrix: result.worldTransform).translation
        
        switch recognizer.state {
        case .began:        // 제스쳐 시작: (윷판의 현재 위치 - 터치된 지점) 차이 계산
            panOffset = boardAnchor.position - hitPosition
        case .changed:      // 제스쳐 중: 터치된 지점 + 저장해둔 오프셋 = 윷판 새 위치 계산
            if let offset = panOffset {
                boardAnchor.position = hitPosition + offset
            }
        default:            // 제스쳐 종료: 오프셋 초기화
            panOffset = nil
        }
    }
    
    @objc func handleRotation(_ recognizer: UIRotationGestureRecognizer) {
        guard arState?.currentState == .adjustingBoard,
              let boardAnchor = yutBoardAnchor else { return }
        
        switch recognizer.state {
        case .began:        // 제스쳐 시작: 현재 회전 값을 저장
            initialBoardRotation = boardAnchor.orientation
        case .changed:      // 제스쳐 중: 제스쳐의 회전 값 -> 회전 쿼터니언 생성
            // Y축 기준 회전
            let rotation = simd_quatf(angle: -Float(recognizer.rotation), axis: [0, 1, 0])
            if let initialRotation = initialBoardRotation {
                boardAnchor.orientation = initialRotation * rotation
            }
        default:            // 제스쳐 종료: 초기화
            initialBoardRotation = nil
        }
    }
    
    // MARK: - Custom Logic: 윷놀이 전
    
    // 윷판 배치
    func placeYutBoard(on anchor: ARAnchor) {
        // 이미 생성되었다면 중복 생성 방지
        if self.yutBoardAnchor != nil { return }
        
        do {
            let boardEntity = try ModelEntity.load(named: "Board.usdz")
            // boardEntity.scale = [2.0, 2.0, 2.0]
            
            let anchorEntity = AnchorEntity(anchor: anchor)
            anchorEntity.addChild(boardEntity)
            
            arView?.scene.addAnchor(anchorEntity)
            self.yutBoardAnchor = anchorEntity
            
            // AppState 변경
            DispatchQueue.main.async {
                self.arState?.currentState = .adjustingBoard
            }
            
            // 평면 시각화 비활성화
            disablePlaneVisualization()
        } catch {
            print("윷판 모델 로딩 실패: \(error)")
        }
    }
    
    // 윷판의 위치를 월드 공간에 고정
    func fixBoardPosition() {
        guard let arView = arView, let boardAnchor = yutBoardAnchor else { return }

        // 월드 기준 변환 행렬 추출
        let worldMatrix = boardAnchor.transformMatrix(relativeTo: nil)
        let fixedAnchor = AnchorEntity(world: worldMatrix)
        
        for child in boardAnchor.children {
            fixedAnchor.addChild(child.clone(recursive: true))
        }
        
        arView.scene.addAnchor(fixedAnchor)
        arView.scene.removeAnchor(boardAnchor)
        self.yutBoardAnchor = fixedAnchor
    }
    
    // 평면 시각화 비활성화 (clear 로 변경하여 물리효과는 유지)
    func disablePlaneVisualization() {
        for (_, entity) in planeEntities {
            entity.model?.materials = [SimpleMaterial(color: .clear, isMetallic: false)]
        }
    }
    
    // MARK: - Custom Logic: 윷 던지기
    
    // 물리 효과가 없는 윷 생성
    func createYuts() {
        // 이전에 있던 윷 제거
        yutHoldingAnchor?.removeFromParent()
        yutEntities.removeAll()
        
        // 카메라에 고정되는 앵커 생성
        let holdingAnchor = AnchorEntity(.camera)
        arView?.scene.addAnchor(holdingAnchor)
        self.yutHoldingAnchor = holdingAnchor
        
        let yutScale: Float = 0.05   // 윷 크기 조절
        for i in 0..<4 {
            do {
                let yutEntity = try ModelEntity.load(named: "Yut.usdz")
                let rotation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                yutEntity.orientation = rotation
                yutEntity.scale = [yutScale, yutScale, yutScale]
                
                let xOffset = (Float(i) - 1.5) * (yutScale * 1.2)
                yutEntity.position = [xOffset, -0.15, -0.4]
                holdingAnchor.addChild(yutEntity)
                yutEntities.append(yutEntity)
            } catch {
                print("윷 엔티티 오류!")
            }
        }
    }
    
    /// CoreMotion의 장치 모션 센서를 사용해서
    /// "던지는 듯한 흔들림"을 감지하는 함수
    func startMonitoringMotion() {
        // 1. 기기가 "디바이스 모션" 기능을 지원하는지 확인
        // (디바이스 모션은: 중력, 회전, 사용자 가속도 등을 통합적으로 감지하는 센서)
        guard motionManager.isDeviceMotionAvailable else {
            print("디바이스 모션 사용 불가")
            return  // 사용 불가이면 아래 코드 실행하지 않고 종료
        }
        
        // 2. 센서 업데이트 주기 설정 (0.05초마다 → 초당 20번 데이터 받음)
        motionManager.deviceMotionUpdateInterval = 0.05
        
        // 3. 디바이스 모션 업데이트 시작
        //    → 센서 데이터를 지속적으로 수신하면서, 클로저 내부에서 처리함
        // 후행 클로저를 활용한 콜백 함수인거야?
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self, let motion = motion else { return }
            
            // 5. 현재 시점의 "순수한 사용자 가속도"만 가져옴
            //    (중력 제외된, 즉 손으로 흔들었을 때 발생한 가속도만)
            let acceleration = motion.userAcceleration
            
            // 6. 가속도의 크기(세기)를 계산
            //    → 벡터의 크기를 구하는 공식: √(x² + y² + z²)
            //    → 실제로 얼마나 세게 흔들었는지를 수치화함
            let magnitude = sqrt(
                acceleration.x * acceleration.x +
                acceleration.y * acceleration.y +
                acceleration.z * acceleration.z
            )
            
            // 7. 이 값을 판단 기준으로 쓸 임계값(Threshold)을 설정
            //    → 흔들림 세기가 1.5 이상일 때만 "던짐"으로 간주
            let threshold = 1.5  // 던지기 감지 민감도
            
            // 8. 이전에 윷을 던진 이후, 일정 시간(1초) 이상 지났는지도 확인
            //    → 연속 감지 방지 (의도치 않은 반복 던지기 차단)
            let cooldown: TimeInterval = 1.0  // 1초 간격 제한
            
            // 9. 조건 두 가지를 모두 만족해야 윷을 던짐
            //    (1) 흔들림 세기 > 임계값
            //    (2) 마지막 던짐 이후 1초 이상 경과
            if magnitude > threshold,
               Date().timeIntervalSince(self.lastThrowTime) > cooldown {
                
                // 10. 던짐 판정을 내렸다면, 현재 시간을 저장해 다음 감지를 잠시 막음
                self.lastThrowTime = Date()
                
                // 11. 실제로 윷을 던지는 물리 로직 실행
                self.throwYuts() // 감지되면 윷 던지기 실행
            }
        }
    }
    
    func throwYuts() {
        // 1. ARView가 존재하는지 확인 (없으면 중단)
        guard let arView = arView else { return }
        
        let count = 4                          // 던질 윷의 개수
        let spacing: Float = 0.07             // 윷 간격 (x축 상에서의 거리)
        let impulseStrength: Float = 10.0     // 던지는 힘의 크기 (임펄스 세기)
        
        // 2. 윷 모델 불러오기 (Reality Composer에서 만든 Yut.usd 파일)
        guard let yutEntity = try? ModelEntity.loadModel(named: "Yut") else {
            print("⚠️ Failed to load Yut")
            return
        }
        
        // 3. 4개의 윷을 반복 생성
        for i in 0..<count {
            let yut = yutEntity.clone(recursive: true) // 모델 복제 (개별 객체로 사용)

            
            // 3-1. 윷 모델의 경계 박스 크기 계산 (충돌 범위로 사용)
            let bounds = yut.visualBounds(relativeTo: nil)
            let size = bounds.extents
            
            // 3-2. 물리 속성 설정 (중력, 질량, 충돌 적용)
            yut.physicsBody = PhysicsBodyComponent(
                massProperties: .default,     // 자동 질량 계산
                material: .default,          // 마찰력, 반발력 기본값
                mode: .dynamic               // 중력 및 충돌 반응 가능
            )
            
            // 3-3. 충돌 감지를 위한 박스 형태의 collision shape 설정
            yut.collision = CollisionComponent(shapes: [.generateBox(size: size)])
            
            // 4. 현재 카메라 위치 가져오기
            if let camTransform = arView.session.currentFrame?.camera.transform {
                // 4-1. 기본 단위 행렬 생성
                var translation = matrix_identity_float4x4
                
                // 4-2. Z축 방향으로 -0.3 → 카메라 기준 30cm 앞쪽에 위치
                translation.columns.3.z = -0.3
                
                // 4-3. X축으로 윷끼리 좌우 퍼지도록 위치 계산
                translation.columns.3.x += (Float(i) - 1.5) * spacing
                
                // 4-4. Z축 기준 살짝 회전 (더 자연스러운 효과)
                let angle: Float = (Float(i) - 1.5) * 0.25
                let rotation = simd_float4x4(SCNMatrix4MakeRotation(angle, 0, 0, 1))
                
                // 4-5. 최종 위치 계산: 카메라 위치 * 이동 * 회전
                let finalTransform = simd_mul(simd_mul(camTransform, translation), rotation)
                
                // 4-6. 윷의 transform 적용
                yut.transform.matrix = finalTransform
                
                // 5. 앵커 생성 및 yut 추가
                let anchor = AnchorEntity(world: yut.transform.matrix)
                anchor.addChild(yut)
                
                // 윷 크기 줄이기
//                yut.scale = SIMD3<Float>(repeating: 0.50)
                arView.scene.anchors.append(anchor)
                
                // 6. 던지는 방향 계산
                // 6-1. 카메라 앞 방향(Z축): RealityKit 기준 뒤로 향하므로 -Z가 앞
                let forward = -simd_make_float3(camTransform.columns.2.x,
                                                camTransform.columns.2.y,
                                                camTransform.columns.2.z)
                
                // 6-2. 카메라 좌우 방향(X축): 윷을 살짝 좌우로 흩뿌리기 위해 사용
                let side = simd_make_float3(camTransform.columns.0.x,
                                            camTransform.columns.0.y,
                                            camTransform.columns.0.z)
                
                // 6-3. 임펄스(충격력) 계산:
                //      → 앞쪽으로 밀고, 좌우로 살짝 분산되도록 조합
//                let downward = SIMD3<Float>(0, -40, 0)  y축 아래로 향하는 벡터
                let impulse = forward * impulseStrength
                            + side * (Float(i) - 1.5) * 1.1
//                            + downward// 💡 아래로 떨어지는 방향의 힘 추가
                
                // 7. 물리 속성 재확인 (중복이긴 하나 안전)
                yut.physicsBody?.mode = .dynamic
                
                // 8. 실제로 윷에 임펄스를 가함 (World 기준 좌표계로)
                yut.applyLinearImpulse(impulse, relativeTo: nil)
            }
        }
    }
}
