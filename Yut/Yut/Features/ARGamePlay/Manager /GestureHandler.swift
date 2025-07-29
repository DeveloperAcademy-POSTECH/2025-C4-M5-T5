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
            guard let tappedEntity = arView.entity(at: tapLocation) else { return }
            var currentEntity: Entity? = tappedEntity
            var pieceToMove: PieceModel?
            
            // 탭 된 Tile Entity 의 UUID를 가지는 PieceModel 찾기
            while currentEntity != nil {
                if let name = currentEntity?.name, let uuid = UUID(uuidString: name) {
                    if let piece = arState.gameManager.pieces.first(where: { $0.id == uuid }) {
                        pieceToMove = piece
                        break
                    }
                }
                currentEntity = currentEntity?.parent
            }
            
            // 찾은 말의 주인이 현재 플레이어인지 ID로 비교
            guard let selectedPiece = pieceToMove,
                  selectedPiece.owner.id == arState.gameManager.currentPlayer.id else {
                print("❌ 현재 플레이어의 말이 아닙니다.")
                return
            }
            
            // 선택된 말의 이동 가능 경로 확인
            guard let yutResult = arState.gameManager.yutResult else { return }
            let destinations = arState.gameManager.routeOptions(for: selectedPiece, yutResult: yutResult, currentRouteIndex: selectedPiece.routeIndex)
            
            if destinations.isEmpty {
                print("🚫 그 말은 움직일 수 없습니다.")
                // TODO: 말이 움직일 수 없는 경우가 있는지 체크하기
            } else {
                let destinationNames = destinations.map { $0.destinationID }
                pieceManager.highlightTiles(named: destinationNames)
                
                arState.selectedPiece = selectedPiece
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
            
            // 탭 된 타일이 이동 가능한 목적지 중 하나인지 확인
            if let name = tileName,
               arState.availableDestinations.contains(name),
               let pieceToMove = arState.selectedPiece {
                
                // 선택된 말이 새 말인지 기존 말인지 확인
                if pieceToMove.position == "_6_6" {
                    pieceManager.placePieceOnBoard(piece: pieceToMove, on: name)
                } else {
                    pieceManager.movePiece(piece: pieceToMove.entity, to: name)
                }
                
                // 말 위치 정보 업데이트
                arState.gameManager.move(piece: pieceToMove, to: name)
                
                // 정보 초기화
                pieceManager.clearAllHighlights()
                arState.selectedPiece = nil
                arState.availableDestinations = []
                
                coordinator?.endTurn()
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
