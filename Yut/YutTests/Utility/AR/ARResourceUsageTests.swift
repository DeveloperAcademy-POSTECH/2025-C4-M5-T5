import Foundation
import RealityKit
import Testing
@testable import Yut

@MainActor
@Suite(.serialized)
struct ARResourceUsageTests {
    @Test
    func remoteFinalPoseKeepsNoPhysicsAndRejectsLateFramesAcrossResume() async throws {
        let fixture = try BoardTestFixture()
        var state = GameState(players: fixture.state.players, currentPlayerIndex: 1)
        for action: GameAction in [.startPlaying, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch)] {
            try state.apply(action)
        }
        fixture.state = state
        let view = try await fixture.prepare()
        defer { fixture.scene.reset() }
        let scene = fixture.scene
        #expect(!scene.canAct)
        let poses = (0..<4).map { ThrowFrame.Pose(index: $0, position: [Float($0) * 0.1, 0.3, 0],
            rotation: [0, 0, 0, 1], scale: [1, 1, 1]) }
        let final = ThrowFrame(gameID: state.id, throwRevision: state.revision, poses: poses,
                              isFinal: true, sequence: 3, timestamp: 0.5)
        scene.showRemoteFrame(final)
        let name = try #require(scene.assetCacheManager.cachedModel(named: "Yut1")).name
        let entity = try #require(view.scene.anchors.compactMap { $0.findEntity(named: name) }.first)
        let anchor = try #require(scene.boardManager?.yutBoardAnchor)
        #expect(abs(entity.position(relativeTo: anchor).y - 0.3) < 0.0001)
        #expect(entity.components[PhysicsBodyComponent.self] == nil)
        #expect(entity.components[CollisionComponent.self] == nil)
        let changed = poses.map { ThrowFrame.Pose(index: $0.index, position: [99, 99, 99], rotation: $0.rotation, scale: $0.scale) }
        scene.showRemoteFrame(ThrowFrame(gameID: state.id, throwRevision: state.revision, poses: changed,
                                        isFinal: false, sequence: 4, timestamp: 0.6))
        scene.pause()
        scene.showRemoteFrame(ThrowFrame(gameID: state.id, throwRevision: state.revision, poses: changed,
                                        isFinal: true, sequence: 5, timestamp: 0.7))
        fixture.viewModel.resume()
        for _ in 0..<100 {
            if scene.arState.placementPhase == .confirmed { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(abs(entity.position(relativeTo: anchor).y - 0.3) < 0.0001)
        #expect(scene.arState.placementPhase == .confirmed)
        // 동기화 스냅샷이 중간 단계를 건너뛰어도 이전 투사의 표시가 남지 않아야 한다.
        for action: GameAction in [.recordThrow(.nak), .dismissResult, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch)] {
            try state.apply(action)
        }
        fixture.state = state
        #expect(fixture.game.receive(.state(state), from: try #require(fixture.transport.hostDeviceID)))
        #expect(entity.scene == nil)
        scene.showRemoteFrame(final)
        #expect(view.scene.anchors.compactMap { $0.findEntity(named: name) }.isEmpty)
    }

    @Test
    func transparentTilesKeepCollisionsAndRenderOnlyWhenHighlightedAfterAnchorClone() async throws {
        let fixture = try BoardTestFixture()
        _ = try await fixture.prepare()
        defer { fixture.scene.reset() }
        let scene = fixture.scene
        let manager = try #require(scene.pieceManager)
        let board = try #require(scene.boardManager)
        let goal = try #require(manager.boardAnchor.findEntity(named: "end"))
        #expect(goal.components[ModelComponent.self] == nil)
        #expect(goal.components[CollisionComponent.self]?.shapes.isEmpty == false)
        let idleTriangles = triangles(in: manager.boardAnchor)
        manager.highlightTiles(named: ["end"])
        #expect(goal.components[ModelComponent.self] != nil)
        #expect(triangles(in: manager.boardAnchor) == idleTriangles + 8064)
        manager.clearAllHighlights()
        #expect(goal.components[ModelComponent.self] == nil)
        #expect(goal.components[CollisionComponent.self]?.shapes.isEmpty == false)

        board.fixBoardPosition()
        manager.boardAnchor = try #require(board.yutBoardAnchor)
        let clonedGoal = try #require(manager.boardAnchor.findEntity(named: "end"))
        #expect(clonedGoal !== goal)
        #expect(clonedGoal.components[ModelComponent.self] == nil)
        #expect(clonedGoal.components[CollisionComponent.self]?.shapes.isEmpty == false)
        manager.highlightTiles(named: ["end"])
        #expect(clonedGoal.components[ModelComponent.self] != nil)
        manager.clearAllHighlights()
        #expect(clonedGoal.components[ModelComponent.self] == nil)
        #expect(triangles(in: manager.boardAnchor) == idleTriangles)
    }

    @Test
    func changingInputAuthorityRefreshesHighlightsWithoutChangingSnapshot() async throws {
        let fixture = try BoardTestFixture()
        _ = try await fixture.prepare()
        defer { fixture.scene.reset() }
        let scene = fixture.scene
        let piece = try #require(fixture.game.state?.currentPieces.first)
        scene.selectPiece(piece.id)
        let state = try #require(fixture.game.state)
        let destination = try #require(state.availableDestinations.first)
        let tile = try #require(scene.pieceManager?.boardAnchor.findEntity(named: destination.cell))
        #expect(tile.components[ModelComponent.self] != nil)
        scene.render(state, models: fixture.models, canAct: false)
        #expect(tile.components[ModelComponent.self] == nil)
        scene.render(state, models: fixture.models, canAct: true)
        #expect(tile.components[ModelComponent.self] != nil)
    }

    @Test
    func goalRemainsSelectableAndCompletesGameWithHiddenIdleMesh() async throws {
        let fixture = try BoardTestFixture()
        _ = try await fixture.prepare()
        defer { fixture.scene.reset() }
        let players = fixture.state.players
        var state = GameState(id: fixture.state.id, players: players, pieces: [
            GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: GameBoard.routes[0].count - 1)),
            GamePiece(playerID: players[0].id, position: .finished),
            GamePiece(playerID: players[1].id), GamePiece(playerID: players[1].id)
        ])
        for action: GameAction in [.startPlaying, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch), .recordThrow(.dho), .dismissResult] {
            try state.apply(action)
        }
        try state.apply(.selectPiece(try #require(state.currentPieces.first).id))
        fixture.state = state
        #expect(fixture.game.receive(.state(state), from: try #require(fixture.transport.hostDeviceID)))
        let goal = try #require(fixture.scene.pieceManager?.boardAnchor.findEntity(named: "end"))
        #expect(goal.components[ModelComponent.self] != nil)
        fixture.scene.gestureHandler.handleGameTap(at: CGPoint(x: 200, y: 400), hitEntity: goal)
        #expect(fixture.game.state?.phase == .finished)
        #expect(fixture.game.state?.winnerID == players[0].id)
        #expect(goal.components[ModelComponent.self] == nil)
    }

    @Test
    func gatheringFramesArePreparedBeforeInputReusedOnResumeAndReleasedOnReset() async throws {
        let fixture = try BoardTestFixture()
        _ = try await fixture.prepare()
        defer { fixture.scene.reset() }
        let frames = fixture.scene.gatheringFrames
        let first = try #require(frames.firstFrame)
        let last = try #require(frames.lastFrame)
        #expect(first.size.width == 880)
        #expect(last.size.height == 1900)
        #expect(await frames.frame(at: 1) === first)
        #expect(await frames.frame(at: 30) === last)
        #expect(await frames.frame(at: 4) != nil)
        fixture.scene.pause()
        fixture.viewModel.resume()
        for _ in 0..<100 {
            if fixture.scene.arState.placementPhase == .confirmed { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(frames.firstFrame === first)
        #expect(frames.lastFrame === last)
        fixture.scene.reset()
        #expect(frames.firstFrame == nil)
        #expect(frames.lastFrame == nil)
        #expect(fixture.scene.assetCacheManager.boardTemplate == nil)
    }

    private func triangles(in entity: Entity) -> Int {
        let own = entity.components[ModelComponent.self]?.mesh.contents.models.reduce(0) { total, model in
            total + model.parts.reduce(0) { $0 + ($1.triangleIndices?.count ?? 0) / 3 }
        } ?? 0
        return own + entity.children.reduce(0) { $0 + triangles(in: $1) }
    }
}
