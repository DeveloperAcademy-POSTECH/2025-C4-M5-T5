import Testing
@testable import Yut

@MainActor
@Suite(.serialized)
struct ARInitializationTests {
    @Test
    func resourcesAndBoardBecomeReadyBeforeGameInput() async throws {
        let fixture = try BoardTestFixture()
        #expect(!fixture.scene.arState.isCoordinatorReady)
        #expect(fixture.scene.pieceManager == nil)
        _ = try await fixture.prepare()
        defer { fixture.scene.reset() }
        #expect(fixture.scene.arState.placementPhase == .confirmed)
        #expect(fixture.scene.arState.isCoordinatorReady)
        #expect(fixture.scene.pieceManager != nil)
        #expect(fixture.scene.arState.gameManager.pieces.count == 4)
        #expect(fixture.scene.arState.coordinator === fixture.scene)
        #expect(fixture.scene.assetCacheManager.cachedModel(named: "Piece3_blue") != nil)
        #expect(fixture.scene.assetCacheManager.cachedModel(named: "Piece4_red") != nil)
    }

    @Test
    func pauseResumeAndResetDoNotDuplicateBoardOrAcceptStaleLoad() async throws {
        let fixture = try BoardTestFixture()
        _ = try await fixture.prepare()
        defer { fixture.scene.reset() }
        let anchor = try #require(fixture.scene.boardManager?.yutBoardAnchor)
        fixture.scene.pause()
        #expect(fixture.viewModel.isSuspended)
        fixture.viewModel.resume()
        for _ in 0..<100 {
            if fixture.scene.arState.placementPhase == .confirmed { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        fixture.viewModel.resumePhase()
        #expect(fixture.scene.boardManager?.yutBoardAnchor === anchor)
        #expect(!fixture.viewModel.isSuspended)
        fixture.scene.reset()
        fixture.scene.resume()
        fixture.scene.reset()
        try await Task.sleep(for: .milliseconds(100))
        #expect(fixture.scene.arState.placementPhase == .loading)
        #expect(fixture.scene.boardManager?.yutBoardAnchor == nil)
        #expect(!fixture.scene.arState.isCoordinatorReady)
    }
}
