import Foundation
import Testing
@testable import Yut

struct GameStateTests {
    private let players = [GamePlayer(name: "A", order: 0), GamePlayer(name: "B", order: 1)]

    @Test
    func regularThrowDoesNotAdvanceTurnUntilPieceMoves() throws {
        var state = GameState(players: players)
        try throwResult(.gae, in: &state)
        #expect(state.phase == .selectingPiece)
        #expect(state.currentPlayer?.name == "A")
        let piece = try #require(state.currentPieces.first)
        try state.apply(.selectPiece(piece.id))
        let destination = try #require(state.availableDestinations.first)
        try state.apply(.selectDestination(destination))
        #expect(state.currentPlayer?.name == "B")
        #expect(state.pieces.first { $0.id == piece.id }?.cell == "_4_6")
    }

    @Test
    func yutGrantsAnotherThrowAfterMoving() throws {
        var state = GameState(players: players)
        try throwResult(.yut, in: &state)
        try moveFirstPiece(in: &state)
        #expect(state.currentPlayer?.name == "A")
        #expect(state.phase == .showingBonus)
        try state.apply(.dismissResult)
        #expect(state.phase == .readyToThrow)
    }

    @Test
    func backDoWithAllPiecesAtHomePassesTurn() throws {
        var state = GameState(players: players)
        try throwResult(.backdho, in: &state)
        #expect(state.currentPlayer?.name == "B")
        #expect(state.phase == .readyToThrow)
    }

    @Test
    func backDoFromFirstCellReturnsPieceHome() throws {
        let piece = GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 1))
        var state = configuredState(piece: piece)
        try throwResult(.backdho, in: &state)
        try moveFirstPiece(in: &state)
        #expect(state.pieces.first { $0.id == piece.id }?.position == .home)
    }

    @Test(arguments: [0, 1, 2])
    func lastCellCompletesRouteWithoutLoopingToStart(route: Int) throws {
        let piece = GamePiece(playerID: players[0].id, position: .onBoard(route: route, index: GameBoard.routes[route].count - 1))
        var state = configuredState(piece: piece, otherOwnPosition: .finished)
        try throwResult(.dho, in: &state)
        try moveFirstPiece(in: &state)
        #expect(state.phase == .finished)
        #expect(state.winner?.name == "A")
    }

    @Test
    func overshootingFinishCompletesPieceButRequiresBothPiecesToWin() throws {
        let piece = GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 19))
        var state = configuredState(piece: piece)
        try throwResult(.mo, in: &state)
        try moveFirstPiece(in: &state)
        #expect(state.pieces.first { $0.id == piece.id }?.position == .finished)
        #expect(state.winner == nil)
        #expect(state.phase == .showingBonus)
    }

    @Test
    func capturesEveryEnemyInStackAndResetsTheirGroups() throws {
        let enemy = players[1].id
        let groupID = UUID()
        let captured = [
            GamePiece(playerID: enemy, position: .onBoard(route: 0, index: 2), groupID: groupID),
            GamePiece(playerID: enemy, position: .onBoard(route: 0, index: 2), groupID: groupID)
        ]
        let own = [GamePiece(playerID: players[0].id), GamePiece(playerID: players[0].id)]
        var state = GameState(players: players, pieces: own + captured)
        try throwResult(.gae, in: &state)
        try moveFirstPiece(in: &state)
        let enemies = state.pieces.filter { $0.playerID == enemy }
        #expect(enemies.allSatisfy { $0.position == .home && $0.groupID == $0.id })
        #expect(state.currentPlayer?.name == "A")
        #expect(state.phase == .showingBonus)
    }

    @Test(arguments: [true, false])
    func friendlyCollisionRequiresCarryChoice(carry: Bool) throws {
        let first = GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 2))
        let second = GamePiece(playerID: players[0].id)
        var state = GameState(players: players, pieces: [first, second] + enemyPieces())
        try throwResult(.gae, in: &state)
        try state.apply(.selectPiece(second.id))
        try state.apply(.selectDestination(try #require(state.availableDestinations.first)))
        #expect(state.phase == .promptingForCarry)
        try state.apply(.resolveCarry(carry))
        let own = state.pieces.filter { $0.playerID == players[0].id }
        #expect(own.allSatisfy { $0.cell == "_4_6" })
        #expect((own[0].groupID == own[1].groupID) == carry)
    }

    @Test
    func carriedPiecesMoveAndFinishTogether() throws {
        let groupID = UUID()
        let own = (0..<2).map { _ in
            GamePiece(playerID: players[0].id, position: .onBoard(route: 1, index: GameBoard.routes[1].count - 2), groupID: groupID)
        }
        var state = GameState(players: players, pieces: own + enemyPieces())
        try throwResult(.gae, in: &state)
        try moveFirstPiece(in: &state)
        #expect(state.pieces.filter { $0.playerID == players[0].id }.allSatisfy { $0.position == .finished })
        #expect(state.winnerID == players[0].id)
    }

    @Test
    func cornerAndCenterOfferValidShortcuts() {
        let corner = GameBoard.destinations(from: .onBoard(route: 0, index: 5), result: .dho)
        #expect(Set(corner.map(\.cell)) == ["_0_5", "_1_5"])
        let center = GameBoard.destinations(from: .onBoard(route: 2, index: 8), result: .dho)
        #expect(Set(center.map(\.cell)) == ["_4_4", "_4_2"])
    }

    @Test
    func backDoAfterCenterShortcutFollowsActualArrivalRoute() throws {
        let piece = GamePiece(playerID: players[0].id, position: .onBoard(route: 2, index: 8))
        var state = configuredState(piece: piece)
        try throwResult(.dho, in: &state)
        try state.apply(.selectPiece(piece.id))
        let shortcut = try #require(state.availableDestinations.first { $0.cell == "_4_4" })
        try state.apply(.selectDestination(shortcut))
        try throwResult(.backdho, in: &state)
        try throwResult(.backdho, in: &state)
        try moveFirstPiece(in: &state)
        try throwResult(.backdho, in: &state)
        try throwResult(.backdho, in: &state)
        try moveFirstPiece(in: &state)
        #expect(state.pieces.first { $0.id == piece.id }?.cell == "_2_4")
    }

    @Test
    func failedAndInvalidMovesAreAtomic() throws {
        var state = GameState(players: players)
        let original = state
        #expect(throws: GameState.RuleError.self) { try state.apply(.selectPiece(UUID())) }
        #expect(state == original)
        try throwResult(.dho, in: &state)
        let enemy = try #require(state.pieces.first { $0.playerID == players[1].id })
        #expect(throws: GameState.RuleError.self) { try state.apply(.selectPiece(enemy.id)) }
        try state.apply(.selectPiece(try #require(state.currentPieces.first).id))
        let selected = state
        #expect(throws: GameState.RuleError.self) {
            try state.apply(.selectDestination(MoveDestination(route: 0, index: 99, cell: "end")))
        }
        #expect(state == selected)
    }

    @Test
    func nakRetriesWithoutChangingTurn() throws {
        var state = GameState(players: players)
        try throwResult(.nak, in: &state)
        #expect(state.phase == .readyToThrow)
        #expect(state.currentPlayer?.name == "A")
    }

    @Test
    func snapshotRoundTripsWithPendingCarryChoice() throws {
        let first = GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 2))
        let second = GamePiece(playerID: players[0].id)
        var state = GameState(players: players, pieces: [first, second] + enemyPieces())
        try throwResult(.gae, in: &state)
        try state.apply(.selectPiece(second.id))
        try state.apply(.selectDestination(try #require(state.availableDestinations.first)))
        let message = GameMessage.state(state)
        let data = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(GameMessage.self, from: data)
        #expect(decoded == message)
    }

    @Test
    func originalResultValuesAndBonusRulesArePreserved() {
        #expect(YutResult.allCases.map(\.rawValue) == [-1, 0, 1, 2, 3, 4, 5])
        #expect(YutResult.allCases.filter(\.grantsAnotherThrow) == [.yut, .mo])
    }

    @Test
    func reselectAndCancelUseLatestPieceDestinations() throws {
        let first = GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 1))
        let second = GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 3))
        var state = GameState(players: players, pieces: [first, second] + enemyPieces())
        try throwResult(.dho, in: &state)
        try state.apply(.selectPiece(first.id))
        let firstDestinations = state.availableDestinations
        try state.apply(.selectPiece(second.id))
        #expect(state.selectedPieceID == second.id)
        #expect(state.availableDestinations != firstDestinations)
        try state.apply(.cancelSelection)
        #expect(state.selectedPieceID == nil)
        #expect(state.availableDestinations.isEmpty)
        #expect(state.phase == .selectingPiece)
    }

    @Test
    func interruptedThrowRetainsTurnAndRejectsLateResult() throws {
        var state = GameState(players: players)
        for action: GameAction in [.startPlaying, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch), .cancelThrow] {
            try state.apply(action)
        }
        #expect(state.phase == .readyToThrow)
        #expect(state.currentPlayer == players[0])
        #expect(state.throwLaunch == nil)
        #expect(throws: GameState.RuleError.self) { try state.apply(.recordThrow(.dho)) }
    }

    private func configuredState(piece: GamePiece, otherOwnPosition: PiecePosition = .home) -> GameState {
        GameState(players: players, pieces: [piece, GamePiece(playerID: players[0].id, position: otherOwnPosition)] + enemyPieces())
    }

    private func enemyPieces() -> [GamePiece] {
        [GamePiece(playerID: players[1].id), GamePiece(playerID: players[1].id)]
    }

    private func throwResult(_ result: YutResult, in state: inout GameState) throws {
        if state.phase == .preparing { try state.apply(.startPlaying) }
        try state.apply(.beginThrow)
        try state.apply(.armThrow)
        try state.apply(.releaseThrow(launch: .testLaunch))
        try state.apply(.recordThrow(result))
        try state.apply(.dismissResult)
    }

    private func moveFirstPiece(in state: inout GameState) throws {
        let piece = try #require(state.currentPieces.first { $0.position != .finished })
        try state.apply(.selectPiece(piece.id))
        try state.apply(.selectDestination(try #require(state.availableDestinations.first)))
    }
}
