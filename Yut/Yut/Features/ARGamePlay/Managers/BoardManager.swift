// Features/ARGamePlay/Services/BoardManager.swift

import RealityKit
import ARKit
import SwiftUI

final class BoardManager {
    private unowned let coordinator: ARCoordinator

        private var arView: ARView? { coordinator.arView }
        private var arState: ARState? { coordinator.arState }

        private(set) var yutBoardAnchor: AnchorEntity?

        init(coordinator: ARCoordinator) {
            self.coordinator = coordinator
        }
    
    /// 윷판 모델을 앵커에 배치
    func placeYutBoard(on anchor: ARAnchor) {
        guard let arView = arView, let arState = arState else { return }
        if yutBoardAnchor != nil { return } // 중복 생성 방지

        do {
            // 1. 윷판 모델 로딩
            let boardEntity = try ModelEntity.load(named: "Board.usdz")
//            boardEntity.generateCollisionShapes(recursive: true)

            // 2. Board와 같은 크기의 보이지 않는 박스 생성
            let boardBounds = boardEntity.visualBounds(relativeTo: nil)
            let boxSize = boardBounds.extents     // SIMD3<Float>(width, height, depth)
            let boxPosition = boardBounds.center  // 월드 기준 중심 위치

            // 3. 충돌용 박스 엔티티 생성
            let invisibleBox = ModelEntity(
                mesh: .generateBox(size: boxSize),
                materials: [SimpleMaterial(color: .clear, isMetallic: false)], // 투명
                collisionShape: .generateBox(size: boxSize),
                mass: 0.0
            )
            invisibleBox.name = "YutBoardCollision" 
            
            invisibleBox.position = boxPosition
            invisibleBox.components.set([
                CollisionComponent(shapes: [.generateBox(size: boxSize)]),
                PhysicsBodyComponent(
                    massProperties: .default,
                    material: .default,
                    mode: .static
                )
            ])

            // 4. 앵커에 추가
            let anchorEntity = AnchorEntity(anchor: anchor)
            anchorEntity.addChild(boardEntity)
            anchorEntity.addChild(invisibleBox)

            arView.scene.addAnchor(anchorEntity)
            self.yutBoardAnchor = anchorEntity

            DispatchQueue.main.async {
                arState.gamePhase = .adjustingBoard
            }

        } catch {
            print("⚠️ 윷판 모델 로딩 실패: \(error)")
        }
    }
//    func placeYutBoard(on anchor: ARAnchor) {
//        guard let arView = arView, let arState = arState else { return }
//        if yutBoardAnchor != nil { return } // 중복 생성 방지
//        
//        do {
//            let boardEntity = try ModelEntity.load(named: "Board.usdz")
//            boardEntity.generateCollisionShapes(recursive: true)
//            
//            let anchorEntity = AnchorEntity(anchor: anchor)
//            anchorEntity.addChild(boardEntity)
//
//            arView.scene.addAnchor(anchorEntity)
//            self.yutBoardAnchor = anchorEntity
//
//            DispatchQueue.main.async {
//                arState.gamePhase = .adjustingBoard
//            }
//        } catch {
//            print("⚠️ 윷판 모델 로딩 실패: \(error)")
//        }
//    }

    /// 현재 앵커 위치를 기준으로 보드를 고정 앵커로 재배치
    func fixBoardPosition() {
        guard let arView = arView, let boardAnchor = yutBoardAnchor else { return }

        let worldMatrix = boardAnchor.transformMatrix(relativeTo: nil)
        let fixedAnchor = AnchorEntity(world: worldMatrix)

        for child in boardAnchor.children {
            fixedAnchor.addChild(child.clone(recursive: true))
        }

        arView.scene.addAnchor(fixedAnchor)
        arView.scene.removeAnchor(boardAnchor)
        self.yutBoardAnchor = fixedAnchor
    }
}
