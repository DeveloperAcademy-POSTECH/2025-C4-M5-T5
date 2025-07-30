//
//  GestureHandler.swift
//  Yut
//
//  Created by yunsly on 7/21/25.
//

import RealityKit
import ARKit

class GestureHandler {
    // ARCoordinator, ARView 와 연결
    weak var coordinator: ARCoordinator?
    weak var arView: ARView?
    
    // 제스쳐 조절 변수
    var initialBoardScale: SIMD3<Float>?    // 크기 조정: 핀치 제스처 초기 스케일 저장
    var panOffset: SIMD3<Float>?            // 위치 조절: 팬 제스처 오프셋 변수
    var initialBoardRotation: simd_quatf?   // 각도 조절: 회전 제스처를 위한 변수
    
    // 의존성 주입: 객체 생성 시점에 전달
    init(coordinator: ARCoordinator) {
        self.coordinator = coordinator
    }
    
    // 화면 탭했을 때 호출
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        // 변경: Coordinator 를 통해 필요한 정보 접근
        guard let arView = self.arView,
              let arState = coordinator?.arState,
              let boardManager = coordinator?.boardManager, let pieceManager = coordinator?.pieceManager else { return }
        
        let tapLocation = recognizer.location(in: arView)
        // 현재 앱 상태에 따라 다른 동작 수헹
        switch arState.gamePhase {
        case .placeBoard:
            guard boardManager.yutBoardAnchor == nil else { return }
            let results = arView.raycast(
                from: tapLocation,
                allowing: .existingPlaneGeometry,
                alignment: .horizontal
            )
            
            // raycast 결과 가장 먼저 맞닿는 평면에 앵커 찍기
            if let firstResult = results.first {
                let anchor = ARAnchor(
                    name: "YutBoardAnchor",
                    transform: firstResult.worldTransform
                )
                arView.session.add(anchor: anchor)      // didAdd 델리게이트 호출됨
            }
            
        case .selectingPieceToMove:
            // 1. 탭한 위치의 엔티티를 직접 가져옵니다.
            guard let tappedEntity = arView.entity(at: tapLocation) else { return }
            
            var foundPiece: PieceModel?
            
            // 2. 탭한 엔티티 또는 그 부모의 이름으로 말을 찾는 안정적인 로직
            // Case 1: 말(Piece) 엔티티 자체를 탭한 경우
            if let pieceUUID = UUID(uuidString: tappedEntity.name) {
                foundPiece = arState.gameManager.pieces.first(where: { $0.id == pieceUUID })
            }
            // Case 2: 말의 일부(자식 메쉬 등)를 탭한 경우, 부모의 이름으로 찾습니다.
            else if let parent = tappedEntity.parent, let pieceUUID = UUID(uuidString: parent.name) {
                foundPiece = arState.gameManager.pieces.first(where: { $0.id == pieceUUID })
            }
            
            // 3. 유효한 말을 찾았는지 확인합니다.
            guard var tappedPiece = foundPiece else {
                print("❌ 탭한 위치에서 말을 찾을 수 없습니다.")
                return
            }
            
            // --- ⭐️ 수정된 그룹 선택 로직 ---
            // 4. 탭한 말이 속한 그룹의 '뿌리 말'(가장 아래 말)을 찾습니다.
            //    부모를 계속 거슬러 올라가, 부모가 더 이상 '말'이 아닐 때까지 반복합니다.
            while let parent = tappedPiece.entity.parent,
                  let parentUUID = UUID(uuidString: parent.name),
                  let parentPiece = arState.gameManager.pieces.first(where: { $0.id == parentUUID }) {
                tappedPiece = parentPiece
            }
            let rootPiece = tappedPiece
            print("ℹ️ 그룹의 뿌리 말을 찾았습니다: \(rootPiece.id.uuidString)")
            
            // 5. 뿌리 말과 그 모든 자식 말들을 하나의 그룹으로 묶습니다.
            //    '따로 가는' 말은 자식이 없으므로, 자기 자신만 그룹이 됩니다.
            var piecesToSelect: [PieceModel] = [rootPiece]
            var queue: [Entity] = [rootPiece.entity]
            while !queue.isEmpty {
                let current = queue.removeFirst()
                for child in current.children {
                    if let childUUID = UUID(uuidString: child.name),
                       let childPiece = arState.gameManager.pieces.first(where: { $0.id == childUUID }) {
                        piecesToSelect.append(childPiece)
                        queue.append(child) // 자식의 자식도 확인하기 위해 큐에 추가
                    }
                }
            }
            print("👍 최종 선택된 그룹: \(piecesToSelect.count)개")
            
            // 그룹의 주인이 현재 플레이어인지 확인합니다.
            guard let owner = piecesToSelect.first?.owner, owner.id == arState.gameManager.currentPlayer.id else {
                print("❌ 현재 플레이어의 말이 아닙니다.")
                return
            }
            
            // 5. 이동 가능한 경로를 계산하고 하이라이트합니다. (기존 로직과 동일)
            guard let yutResult = arState.gameManager.yutResult else { return }
            let destinations = arState.gameManager.routeOptions(for: tappedPiece, yutResult: yutResult, currentRouteIndex: tappedPiece.routeIndex)
            
            if destinations.isEmpty {
                print("🚫 그 말은 움직일 수 없습니다.")
            } else {
                let destinationNames = destinations.map { $0.destinationID }
                pieceManager.highlightTiles(named: destinationNames)
                
                arState.selectedPieces = piecesToSelect
                arState.availableDestinations = destinationNames
                arState.gamePhase = .selectingDestination
            }
            
        case .selectingDestination:
            guard let tappedEntity = arView.entity(at: tapLocation) else { return }
            
            // 경로(타일)를 탭했는지 확인
            var currentEntity: Entity? = tappedEntity
            var tileName: String?
            while currentEntity != nil {
                if let name = currentEntity?.name, name.starts(with: "_") {
                    tileName = name
                    break
                }
                currentEntity = currentEntity?.parent
            }
            
            
            // 탭 된 타일이 이동 가능한 목적지 중 하나인지 확인, 처리 위임
            if let name = tileName,
               arState.availableDestinations.contains(name),
               let piecesToMove = arState.selectedPieces {
                
                coordinator?.processMoveRequest(pieces: piecesToMove, to: name)
            }
            

        default:
            break
        }
    }
    
    // 크기 조절 제스처: 줌인 줌아웃 할 때 호출
    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        
        // 변경: Coordinator 를 통해 필요한 정보 접근
        guard let arState = coordinator?.arState,
              let boardAnchor = coordinator?.boardManager.yutBoardAnchor else {
            return
        }
        
        // 윷판을 조정하는 상태인지 확인
        guard arState.gamePhase == .adjustingBoard else { return }
        
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
        
        // 변경: Coordinator 를 통해 필요한 정보 접근
        guard let arView = self.arView,
              let arState = coordinator?.arState,
              let boardAnchor = coordinator?.boardManager.yutBoardAnchor else {
            return
        }
        
        guard arState.gamePhase == .adjustingBoard else { return }
        
        // 수평면 위의 3D 좌표 얻기
        let panLocaton = recognizer.location(in: arView)
        guard let result = arView.raycast(from: panLocaton, allowing: .existingPlaneGeometry, alignment: .horizontal).first else {
            return
        }
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
        // 변경: Coordinator 를 통해 필요한 정보 접근
        guard let arState = coordinator?.arState,
              let boardAnchor = coordinator?.boardManager.yutBoardAnchor else {
            return
        }
        
        guard arState.gamePhase == .adjustingBoard else { return }
        
        switch recognizer.state {
        case .began:        // 제스쳐 시작: 현재 회전 값을 저장
            initialBoardRotation = boardAnchor.orientation
        case .changed:      // 제스쳐 중: 제스쳐의 회전 값 -> 회전 쿼터니언 생성
            // Y축 기준 회전
            let rotation = simd_quatf(
                angle: -Float(recognizer.rotation),
                axis: [0, 1, 0]
            )
            if let initialRotation = initialBoardRotation {
                boardAnchor.orientation = initialRotation * rotation
            }
        default:            // 제스쳐 종료: 초기화
            initialBoardRotation = nil
        }
    }
    
}
