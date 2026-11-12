// Features/ARGamePlay/Services/BoardManager.swift

import ARKit
import RealityKit
import SwiftUI

@MainActor
final class BoardManager {
    private let scene: RealityKit.Scene?
    private let assets: AssetCacheManager

    private(set) var yutBoardAnchor: AnchorEntity?

    init(scene: RealityKit.Scene, assets: AssetCacheManager) {
        self.scene = scene
        self.assets = assets
    }

    /// 윷판 모델을 앵커에 배치
    func placeYutBoard(on anchor: ARAnchor) {
        guard let scene = scene else {
            print("❌ [BoardManager] Scene is nil - 윷판을 추가할 수 없습니다.")
            
            return
        }
        print("✅ [BoardManager] Scene is ready, proceeding to add board")
        if yutBoardAnchor != nil { return } // 중복 생성 방지

        do {
            // 이미 준비한 템플릿을 복제해 같은 USDZ를 배치 시 다시 읽지 않는다.
            let boardEntity = try makeBoard()
            boardEntity.generateCollisionShapes(recursive: true)

            // 골인 지점을 포함한 기존 충돌 범위를 유지한다.
            let boardBounds = boardEntity.visualBounds(relativeTo: nil)
            let boxSize = boardBounds.extents     // SIMD3<Float>(width, height, depth)
            let boxPosition = boardBounds.center  // 월드 기준 중심 위치

            // 렌더링 메시 없이 충돌만 처리해 판 밖 박스가 보이거나 그림자를 만들지 않게 한다.
            let invisibleBox = ModelEntity()
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
#if targetEnvironment(simulator)
            let anchorEntity = AnchorEntity(world: anchor.transform) // 시뮬레이터에서는 월드 기준 anchor
#else
            let anchorEntity = AnchorEntity(.anchor(identifier: anchor.identifier)) // 실제 디바이스에서는 ARAnchor 기반
#endif
            anchorEntity.addChild(boardEntity)
            anchorEntity.addChild(invisibleBox)
            
            scene.addAnchor(anchorEntity)
            yutBoardAnchor = anchorEntity
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
//            let anchorEntity = AnchorEntity(.anchor(identifier: anchor.identifier))
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

    func reset() {
        yutBoardAnchor?.removeFromParent()
        yutBoardAnchor = nil
    }

    private func makeBoard() throws -> Entity {
        guard let template = assets.boardTemplate else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        return template.clone(recursive: true)
    }

    /// 현재 앵커 위치를 기준으로 보드를 고정 앵커로 재배치
    func fixBoardPosition() {
        guard let scene = scene, let boardAnchor = yutBoardAnchor else { return }

        let worldMatrix = boardAnchor.transformMatrix(relativeTo: nil)
        let fixedAnchor = AnchorEntity(world: worldMatrix)

        for child in boardAnchor.children {
            fixedAnchor.addChild(child.clone(recursive: true))
        }

        scene.addAnchor(fixedAnchor)
        scene.removeAnchor(boardAnchor)
        yutBoardAnchor = fixedAnchor
    }
}

extension BoardManager {
    /// Guest가 Host의 말판 정보를 받아서 말판을 동일 위치에 배치
    func placeBoardFromHost(on anchor: ARAnchor) {
        // placeYutBoard를 직접 호출 (중복 호출 방지)
        placeYutBoard(on: anchor)
    }
}
