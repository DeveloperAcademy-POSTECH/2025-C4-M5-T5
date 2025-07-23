//
//  ARContentManager.swift
//  Yut
//
//  Created by yunsly on 7/21/25.
//
//  RealityKit 과 관련된 모든 시각적 처리를 담당

import SwiftUI
import RealityKit
import ARKit
import Combine
import CoreMotion


class ARContentManager {
    
    // MARK: - Properties
    weak var coordinator: ARCoordinator?
    
    // 사용자가 조작할 윷판 앵커와 시각화된 평면들을 관리
    var yutBoardAnchor: AnchorEntity?
    var planeEntities: [UUID: ModelEntity] = [:]
    
    // 윷 관련 변수
    var yutEntities: [Entity] = []
    var yutHoldingAnchor: AnchorEntity?
    
    // 하이라이트된 엔티티들의 기존값 저장
    var originalMaterials: [String: RealityFoundation.Material] = [:]
    
    // token properties
    var pieceEntities: [Entity] = []
    private var animationSubscriptions = Set<AnyCancellable>()
    
    // CoreMotion Properties
    private let motionManager = CMMotionManager()
    private var lastThrowTime = Date(timeIntervalSince1970: 0)
    
    
    init(coordinator: ARCoordinator) {
        self.coordinator = coordinator
    }
    
    // MARK: - Board Management
    
    // 윷판 배치
    func placeYutBoard(on anchor: ARAnchor) {
        // 이미 생성되었다면 중복 생성 방지
        guard let arView = coordinator?.arView, let arState = coordinator?.arState else { return }
        if self.yutBoardAnchor != nil { return }
        
        do {
            let boardEntity = try ModelEntity.load(named: "Board.usdz")
            boardEntity.generateCollisionShapes(recursive: true)
            // boardEntity.scale = [2.0, 2.0, 2.0]
            
            let anchorEntity = AnchorEntity(anchor: anchor)
            anchorEntity.addChild(boardEntity)
            
            arView.scene.addAnchor(anchorEntity)
            self.yutBoardAnchor = anchorEntity
            
            // AppState 변경
            DispatchQueue.main.async {
                arState.currentState = .adjustingBoard
            }
            
            // 평면 시각화 비활성화
            disablePlaneVisualization()
        } catch {
            print("윷판 모델 로딩 실패: \(error)")
        }
    }
    
    // 윷판의 위치를 월드 공간에 고정
    func fixBoardPosition() {
        guard let arView = coordinator?.arView, let boardAnchor = yutBoardAnchor else { return }
        
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
    
    // MARK: - Yut Management
    
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
        guard let arView = coordinator?.arView else { return }
        
//        let count = 4                          // 던질 윷의 개수
        let yutNames = ["Yut1", "Yut2", "Yut3", "Yut4_back"] // 다른 모델명 사용
        let spacing: Float = 0.07             // 윷 간격 (x축 상에서의 거리)
        let impulseStrength: Float = 10.0     // 던지는 힘의 크기 (임펄스 세기)
        
//        // 2. 윷 모델 불러오기 (Reality Composer에서 만든 Yut.usd 파일)
//        guard let yutEntity = try? ModelEntity.loadModel(named: "Yut") else {
//            print("⚠️ Failed to load Yut")
//            return
//        }
        
        // 3. 4개의 윷을 반복 생성
        for i in 0..<yutNames.count {
            let modelName = yutNames[i]
            
            guard let yut = try? ModelEntity.loadModel(named: modelName) else {
                        print("⚠️ Failed to load \(modelName)")
                        continue
                    }
            
//            let yut = yutEntity.clone(recursive: true) // 모델 복제 (개별 객체로 사용)
            
            
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
                                yut.scale = SIMD3<Float>(repeating: 0.1)
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
    
    // MARK: - Token Management
    
    // 말을 지정된 타일 위에 배치
    // TODO: 어떤 말을 배치할 것인지 인자로 넘기자.
    func placeNewPiece(on tileName: String) {
        guard let boardEntity = yutBoardAnchor?.children.first,
              let tileEntity = boardEntity.findEntity(named: tileName) else {
            print("오류: \(tileName) 타일을 찾을 수 없습니다.")
            return
        }
        
        do {
            let pieceEntity = try ModelEntity.load(named: "Piece1_yellow.usdz")
            pieceEntity.generateCollisionShapes(recursive: true)
            pieceEntity.scale = [0.3, 8.0, 0.3]
            
            // 로드한 '말' 엔티티에 고유한 이름을 부여
            pieceEntity.name = "yut_piece_\(pieceEntities.count)"
            
            pieceEntity.position = [0, 0.2, 0]
            tileEntity.addChild(pieceEntity)
            pieceEntities.append(pieceEntity)
            print("\(tileName)에 새로운 말을 배치했습니다.")
            
        } catch {
            print("오류: 말 모델(Piece.usdz) 로딩에 실패했습니다: \(error)")
        }
    }
    
    func movePiece(piece: Entity, to tileName: String) {
        guard let boardEntity = yutBoardAnchor?.children.first,
              let destinationTile = boardEntity.findEntity(named: tileName) else {
            print("오류: 목적지 \(tileName) 타일을 찾을 수 없습니다.")
            return
        }
        
        
        var destinationPosition = destinationTile.position(relativeTo: nil)
        destinationPosition.y += 0.02
        
        var destinationTransform = Transform(matrix: piece.transformMatrix(relativeTo: nil))
        destinationTransform.translation = destinationPosition
        
        piece.move(
            to: destinationTransform,
            relativeTo: nil,
            duration: 0.5,
            timingFunction: .easeInOut
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("\(piece.name)의 이동 애니메이션 완료. 부모를 \(tileName)으로 변경합니다.")
            
            piece.setParent(destinationTile)
            piece.setPosition([0, 0.02, 0], relativeTo: destinationTile)
        }
        
        print("\(piece.name) 말을 \(tileName)으로 이동 시작.")
    }
    
    // MARK: - Plane Management
    
    func addPlane(for anchor: ARPlaneAnchor) {
        guard let arView = coordinator?.arView else { return }
        
        var planeMesh: MeshResource
        do {
            let vertices = anchor.geometry.vertices.map { SIMD3<Float>($0) }
            let faceIndices = anchor.geometry.triangleIndices
            
            var descriptor = MeshDescriptor()
            descriptor.positions = MeshBuffers.Positions(vertices)
            descriptor.primitives = .triangles(faceIndices.map { UInt32($0)})
            planeMesh = try .generate(from: [descriptor])
            
        } catch {
            print("평면 앵커용 메시 생성 오류: \(error)")
            return
        }
        
        let planeMaterial = SimpleMaterial(color: .green.withAlphaComponent(0.2), isMetallic: false)
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
        
        planeEntity.generateCollisionShapes(recursive: false)
        planeEntity.components.set(PhysicsBodyComponent(mode: .static))
        
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(planeEntity)
        
        arView.scene.addAnchor(anchorEntity)
        self.planeEntities[anchor.identifier] = planeEntity
    }
    
    func updatePlane(for anchor: ARPlaneAnchor) {
        guard let planeEntity = self.planeEntities[anchor.identifier] else { return }
        
        var updatedMesh: MeshResource
        do {
            let vertices = anchor.geometry.vertices.map { SIMD3<Float>($0) }
            let faceIndices = anchor.geometry.triangleIndices
            var descriptor = MeshDescriptor()
            descriptor.positions = MeshBuffers.Positions(vertices)
            descriptor.primitives = .triangles(faceIndices.map { UInt32($0) })
            updatedMesh = try .generate(from: [descriptor])
        } catch {
            print("평면 앵커용 메시 업데이트 오류: \(error)")
            return
        }
        
        planeEntity.model?.mesh = updatedMesh
        planeEntity.generateCollisionShapes(recursive: false)
    }
    
    func disablePlaneVisualization() {
        for (_, entity) in planeEntities {
            entity.model?.materials = [SimpleMaterial(color: .clear, isMetallic: false)]
        }
    }
    
    // MARK: - Highlight Management
    func highlightPositions(names: [String]) {
        
        guard let boardEntity = yutBoardAnchor?.children.first else {
            print("오류: 윷판 엔티티를 찾을 수 없습니다.")
            return
        }
        
        clearHighlights()
        
        for name in names {
            if let tileEntity = boardEntity.findEntity(named: name) as? ModelEntity {
                // 현재 머티리얼 저장
                if let material = tileEntity.model?.materials.first {
                    originalMaterials[name] = material
                }
                
                var emissiveMaterial = UnlitMaterial()
                emissiveMaterial.color = .init(tint: .yellow.withAlphaComponent(0.8))
                
                
                // 모델의 머티리얼을 발광 머티리얼로 교체
                if var model = tileEntity.model {
                    model.materials = [emissiveMaterial]
                    tileEntity.model = model
                    
                    print("\(name) 위치를 하이라이트했습니다.")
                } else {
                    print("오류: \(name) 위치에는 Model 컴포넌트가 없습니다.")
                }
            } else {
                print("오류: \(name) 이라는 이름의 타일을 찾지 못했습니다.")
            }
        }
    }
    
    func clearHighlights() {
        guard let boardEntity = yutBoardAnchor?.children.first else { return }
        
        for (name, originalMaterial) in originalMaterials {
            if let tileEntity = boardEntity.findEntity(named: name) as? ModelEntity,
               var model = tileEntity.model {
                model.materials = [originalMaterial]
                tileEntity.model = model
            }
        }
        originalMaterials.removeAll()
    }
    
}
