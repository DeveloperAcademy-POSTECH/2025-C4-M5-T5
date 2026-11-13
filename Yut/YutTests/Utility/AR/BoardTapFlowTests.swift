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
        #expect(fixture.game.state?.selectedPieceID == first.id)
        #expect(fixture.game.state?.availableDestinations == firstDestination)
        fixture.viewModel.cancelSelection()
        scene.gestureHandler.handleGameTap(at: CGPoint(x: 200, y: 400), hitEntity: second.entity)
        #expect(fixture.game.state?.selectedPieceID == second.id)
        #expect(fixture.game.state?.availableDestinations != firstDestination)
        let destination = try #require(fixture.game.state?.availableDestinations.first)
        let tile = try #require(scene.pieceManager?.boardAnchor.findEntity(named: destination.cell))
        scene.gestureHandler.handleGameTap(at: CGPoint(x: 200, y: 400), hitEntity: tile)
        #expect(fixture.game.state?.pieces.first { $0.id == second.id }?.cell == destination.cell)
        #expect(fixture.game.state?.selectedPieceID == nil)
        #expect(fixture.game.state?.phase == .movingPiece)
        #expect(fixture.game.state?.currentPlayer?.name == "A")
        #expect(second.position == destination.cell)
    }

    @Test(arguments: [true, false])
    func tappingFriendOrItsTileAutomaticallyCarriesThroughSharedState(tapsPiece: Bool) async throws {
        let fixture = try BoardTestFixture()
        let players = fixture.state.players
        fixture.state = GameState(players: players, pieces: [
            GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 1)),
            GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 2)),
            GamePiece(playerID: players[1].id), GamePiece(playerID: players[1].id)
        ])
        for action: GameAction in [.startPlaying, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch),
                                  .recordThrow(.dho), .dismissResult] { try fixture.state.apply(action) }
        _ = try await fixture.prepare()
        defer { fixture.scene.reset() }
        let scene = fixture.scene
        let pieces = scene.arState.gameManager.players[0].pieces
        let first = try #require(pieces.first)
        let second = try #require(pieces.last)
        scene.gestureHandler.handleGameTap(at: CGPoint(x: 200, y: 400), hitEntity: first.entity)
        let tile = try #require(scene.boardManager?.yutBoardAnchor?.findEntity(named: second.position))
        scene.gestureHandler.handleGameTap(at: CGPoint(x: 200, y: 400), hitEntity: tapsPiece ? second.entity : tile)
        #expect(fixture.game.state?.phase == .movingPiece)
        #expect(fixture.game.state?.selectedPieceID == nil)
        let own = try #require(fixture.game.state?.currentPieces)
        #expect(own[0].cell == own[1].cell)
        #expect(own[0].groupID == own[1].groupID)
        #expect(own[0].history == own[1].history)
        #expect(fixture.game.state?.pendingResults.isEmpty == true)
    }

    @Test
    func finishUsesExplicitActionAndOldEndTileCannotMovePiece() async throws {
        let fixture = try BoardTestFixture()
        let players = fixture.state.players
        fixture.state = GameState(players: players, pieces: [
            GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: GameBoard.routes[0].count - 1)),
            GamePiece(playerID: players[0].id, position: .finished),
            GamePiece(playerID: players[1].id), GamePiece(playerID: players[1].id)
        ])
        for action: GameAction in [.startPlaying, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch),
                                  .recordThrow(.dho), .dismissResult] { try fixture.state.apply(action) }
        _ = try await fixture.prepare()
        defer { fixture.scene.reset() }
        let piece = try #require(fixture.state.currentPieces.first)
        fixture.viewModel.finishPiece()
        #expect(fixture.game.state?.phase == .selectingPiece)
        fixture.scene.selectPiece(piece.id)
        let tile = try #require(fixture.scene.boardManager?.yutBoardAnchor?.findEntity(named: "_6_6"))
        let view = try #require(fixture.scene.arView)
        let currentCenter = try #require(fixture.scene.pieceManager?.worldPosition(ofTile: "_6_6"))
        let front = view.cameraTransform.matrix * SIMD4<Float>(0, 0, -2, 1)
        tile.setPosition(tile.position(relativeTo: nil) + SIMD3(front.x, front.y, front.z) - currentCenter, relativeTo: nil)
        let projected = try #require(fixture.scene.finishActionPosition())
        #expect(view.bounds.contains(projected))
        let before = fixture.game.state
        fixture.scene.selectDestination("end")
        #expect(fixture.game.state == before)
        fixture.viewModel.finishPiece()
        #expect(fixture.game.state?.phase == .finished)
        #expect(fixture.game.state?.winnerID == players[0].id)
        #expect(fixture.scene.finishActionPosition() == nil)
        #expect(fixture.viewModel.playerProgress[0].finishedNumbers.count == 2)
        fixture.viewModel.finishPiece()
        #expect(fixture.game.state?.revision == (before?.revision ?? 0) + 1)
    }

    @Test
    func allResultHighlightsAndBackDoReturnKeepVisibleStartPiece() async throws {
        let fixture = try BoardTestFixture()
        var state = GameState(players: fixture.state.players, pieces: fixture.state.pieces)
        for result: YutResult in [.mo, .backdho] {
            if state.phase == .preparing { try state.apply(.startPlaying) }
            for action: GameAction in [.beginThrow, .armThrow, .releaseThrow(launch: .testLaunch), .recordThrow(result), .dismissResult] {
                try state.apply(action)
            }
        }
        fixture.state = state
        _ = try await fixture.prepare()
        defer { fixture.scene.reset() }
        let first = try #require(state.currentPieces.first)
        fixture.scene.selectPiece(first.id)
        let destinations = try #require(fixture.game.state?.availableDestinations)
        #expect(Set(destinations.map(\.cell)) == ["_0_5", "_6_6"])
        for destination in destinations {
            let tile = try #require(fixture.scene.boardManager?.yutBoardAnchor?.findEntity(named: destination.cell))
            #expect(tile.components[ModelComponent.self] != nil)
        }
        fixture.scene.selectDestination("_6_6")
        #expect(fixture.game.state?.pendingResults.map(\.result) == [.mo])
        #expect(fixture.game.state?.pieces.first?.position == .onBoard(route: 0, index: 0))
        try await Task.sleep(for: .milliseconds(850))
        let rendered = try #require(fixture.scene.arState.gameManager.pieces.first { $0.id == first.id })
        #expect(rendered.entity.parent?.name == "_6_6")
        #expect(rendered.entity.isActive)
        #expect(fixture.viewModel.playerProgress[0].waitingNumbers.isEmpty)
        #expect(fixture.viewModel.playerProgress[0].finishedNumbers.isEmpty)
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
            if fixture.game.state?.phase == .selectingDestination { fixture.viewModel.cancelSelection() }
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
