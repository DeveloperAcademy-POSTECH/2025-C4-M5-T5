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
            //            guard let tappedEntity = arView.entity(at: tapLocation),
            //                  // 탭한 것이 '말' 엔티티인지 확인 (관리 배열에 포함되어 있는지)
            //                  let piece = contentManager.pieceEntities.first(where: { $0 == tappedEntity })
            //            else { return }
            //
            //            arState.selectedPiece = piece
            //            arState.actionStream.send(.showDestinationsForExistingPiece)
            // --- 디버깅을 위해 로그를 추가한 '기존 말 선택' 로직 ---
            
            //            // 1. 탭한 위치에 어떤 엔티티가 있는지 확인합니다.
            //            if let tappedEntity = arView.entity(at: tapLocation) {
            //                print("--- 탭 감지 ---")
            //                print("감지된 엔티티 이름: \(tappedEntity.name)")
            //
            //                // 2. 감지된 엔티티가 우리가 관리하는 '말' 중 하나인지 확인합니다.
            //                // 탭 된 엔티티의 이름이 "yut_piece_"로 시작하는지 확인합니다.
            //                let pieceName = tappedEntity.name
            //                if pieceName
            //                    .starts(with: "yut_piece_") {
            //
            //                    // 이름으로 관리 배열에서 해당 말을 찾습니다.
            //                    if let piece = contentManager.pieceEntities.first(
            //                        where: { $0.name == pieceName
            //                        }) {
            //                        print("성공: \(pieceName) 말을 탭했습니다.")
            //
            //                        // 기존 로직 실행
            //                        arState.selectedPiece = piece
            //                        arState.actionStream
            //                            .send(.showDestinationsForExistingPiece)
            //                    }
            //                } else {
            //                    print("탭한 엔티티(\(tappedEntity.name))는 말이 아닙니다.")
            //                }
            //
            //            } else {
            //                print("--- 탭 실패: 아무것도 감지되지 않았습니다. ---")
            //                print("Collision Shape이 없거나, 너무 작거나, 다른 객체에 가려졌을 수 있습니다.")
            //            }
            guard let tappedEntity = arView.entity(at: tapLocation) else {
                print("탭 실패: 아무것도 감지되지 않았습니다.")
                return
            }
            
            // --- 탭한 엔티티부터 부모로 거슬러 올라가며 '말'을 찾는 최종 로직 ---
            var currentEntity: Entity? = tappedEntity
            var foundPiece: Entity?
            
            while currentEntity != nil {
                // 현재 엔티티의 이름이 "yut_piece_"로 시작하는지 확인합니다.
                if let name = currentEntity?.name, name.starts(with: "yut_piece_") {
                    
                    // 이름이 일치하는 엔티티가 우리가 관리하는 배열에 있는지 최종 확인합니다.
                    if let piece = pieceManager.pieceEntities.first(where: { $0.name == name }) {
                        foundPiece = piece
                        break // 찾았으므로 루프를 중단합니다.
                    }
                }
                currentEntity = currentEntity?.parent // 부모 엔티티로 이동해서 계속 찾습니다.
            }
            
            // 최종적으로 말을 찾았다면, 다음 단계를 진행합니다.
            if let piece = foundPiece {
                print("성공: \(piece.name) 말을 탭했습니다.")
                
                // 기존 로직 실행
                arState.selectedPiece = piece
                arState.actionStream.send(.showDestinationsForExistingPiece)
                
            } else {
                print("실패: 탭한 엔티티(\(tappedEntity.name)) 또는 그 부모 중에 관리 중인 말이 없습니다.")
            }
            
        case .selectingDestination:
            
            guard let tappedEntity = arView.entity(at: tapLocation) else {
                return
            }
            var currentEntity: Entity? = tappedEntity
            var tileName: String?
            
            // 부모 엔티티 찾음 (_row_col)
            while currentEntity != nil {
                if let name = currentEntity?.name, name.starts(with: "_") {
                    tileName = name
                    break
                }
                currentEntity = currentEntity?.parent
            }
            
            
            if let name = tileName, arState.possibleDestinations
                .contains(name) {
                
                // 만약 선택된 말이 있다면 '이동', 없다면 '새로 배치'
                if let selectedPiece = arState.selectedPiece {
                    // <<-- 이동 로직 -->>
                    pieceManager.movePiece(piece: selectedPiece, to: name)
                } else {
                    // <<-- 기존의 새 말 배치 로직 -->>
                    pieceManager.placeNewPiece(on: name)
                }
                
                // 마무리 작업
                pieceManager.clearHighlights()
                arState.selectedPiece = nil // 선택된 말 초기화
                arState.gamePhase = .selectingPieceToMove
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
