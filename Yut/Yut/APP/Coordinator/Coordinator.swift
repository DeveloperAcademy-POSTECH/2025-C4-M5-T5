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

// ARView의 이벤트의 처리하고 SwiftUI와 연결
class Coordinator: NSObject, ARSessionDelegate {
    weak var arView: ARView?    // 순환 참조 방지 : 소유X 필요할 때만 잠깐 참조
    
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
                    self?.startShakeDetection()
                    
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
    
    // 흔들림 감지 시작, 감지 시 윷을 던지도록 설정
    func startShakeDetection() {
        // 흠
    }
}
