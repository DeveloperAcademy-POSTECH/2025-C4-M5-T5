import Foundation
import RealityKit
import Testing
@testable import Yut

@MainActor
@Suite(.serialized)
struct BoardTapFlowTests {
    @Test
    func nestedPieceCanBeReselectedThenMovedThroughAuthoritativeState() async throws {
        let fixture = try BoardTestFixture()
        _ = try await fixture.prepare()
        defer { fixture.scene.reset() }
        let scene = fixture.scene
        let pieces = fixture.scene.arState.gameManager.players[0].pieces
        let first = try #require(pieces.first)
        let second = try #require(pieces.last)
        let nested = Entity()
        first.entity.addChild(nested)
        scene.gestureHandler.handleGameTap(at: CGPoint(x: 200, y: 400), hitEntity: nested)
        #expect(fixture.game.state?.selectedPieceID == first.id)
        let firstDestination = fixture.game.state?.availableDestinations
        scene.gestureHandler.handleGameTap(at: CGPoint(x: 200, y: 400), hitEntity: second.entity)
        #expect(fixture.game.state?.selectedPieceID == second.id)
        #expect(fixture.game.state?.availableDestinations != firstDestination)
        let destination = try #require(fixture.game.state?.availableDestinations.first)
        let tile = try #require(scene.pieceManager?.boardAnchor.findEntity(named: destination.cell))
        scene.gestureHandler.handleGameTap(at: CGPoint(x: 200, y: 400), hitEntity: tile)
        #expect(fixture.game.state?.pieces.first { $0.id == second.id }?.cell == destination.cell)
        #expect(fixture.game.state?.selectedPieceID == nil)
        #expect(fixture.game.state?.currentPlayer?.name == "B")
        #expect(second.position == destination.cell)
    }

    @Test
    func opponentOutOfPhaseAndDetachedPieceCannotBeSelected() async throws {
        let fixture = try BoardTestFixture()
        _ = try await fixture.prepare()
        defer { fixture.scene.reset() }
        let scene = fixture.scene
        let manager = scene.arState.gameManager
        let enemy = try #require(manager.players[1].pieces.first)
        scene.gestureHandler.handleGameTap(at: CGPoint(x: 200, y: 400), hitEntity: enemy.entity)
        #expect(fixture.game.state?.selectedPieceID == nil)
        let own = try #require(manager.players[0].pieces.first)
        scene.pause()
        scene.gestureHandler.handleGameTap(at: CGPoint(x: 200, y: 400), hitEntity: own.entity)
        #expect(fixture.game.state?.selectedPieceID == nil)
    }

    @Test
    func screenAssistanceSelectsAndReselectsThroughBoardCollider() async throws {
        let fixture = try BoardTestFixture()
        let view = try await fixture.prepare()
        defer { fixture.scene.reset() }
        let scene = fixture.scene
        let anchor = try #require(scene.boardManager?.yutBoardAnchor)
        // 실제 모델 배치 애니메이션과 무관한 화면 좌표를 만들어 44pt 입력 경로를 검증한다.
        try await Task.sleep(for: .milliseconds(700))
        let own = scene.arState.gameManager.players[0].pieces
        for (index, piece) in own.enumerated() {
            piece.entity.removeFromParent()
            piece.entity = ModelEntity(mesh: .generateSphere(radius: 0.005))
            piece.entity.name = piece.id.uuidString
            anchor.addChild(piece.entity)
            let camera = view.cameraTransform.matrix
            let local = SIMD4<Float>(Float(index) * 0.25 - 0.125, 0, -2, 1)
            let world = camera * local
            piece.entity.setPosition(SIMD3(world.x, world.y, world.z), relativeTo: nil)
        }
        let collider = Entity()
        collider.name = "YutBoardCollision"
        for piece in own {
            let center = try #require(view.project(piece.entity.position(relativeTo: nil)))
            scene.gestureHandler.handleGameTap(at: CGPoint(x: center.x + 20, y: center.y), hitEntity: collider)
            #expect(fixture.game.state?.selectedPieceID == piece.id)
        }
        let last = try #require(own.last)
        let center = try #require(view.project(last.entity.position(relativeTo: nil)))
        fixture.viewModel.cancelSelection()
        last.entity.removeFromParent()
        scene.gestureHandler.handleGameTap(at: CGPoint(x: center.x + 20, y: center.y), hitEntity: collider)
        #expect(fixture.game.state?.selectedPieceID == nil)
    }
}
