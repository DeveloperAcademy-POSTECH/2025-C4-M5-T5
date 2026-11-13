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
        #expect(state.phase == .movingPiece)
        #expect(throws: GameState.RuleError.self) { try state.apply(.beginThrow) }
        try state.apply(.completeMove)
        #expect(state.currentPlayer?.name == "B")
        #expect(state.pieces.first { $0.id == piece.id }?.cell == "_4_6")
    }

    @Test
    func yutGrantsAnotherThrowBeforeMovingAndOnlyOnce() throws {
        var state = GameState(players: players)
        try throwResult(.yut, in: &state)
        #expect(state.currentPlayer?.name == "A")
        #expect(state.phase == .readyToThrow)
        #expect(state.pendingResults.map(\.result) == [.yut])
        let piece = try #require(state.currentPieces.first)
        #expect(throws: GameState.RuleError.self) { try state.apply(.selectPiece(piece.id)) }
        try throwResult(.gae, in: &state)
        try moveFirstPiece(in: &state)
        #expect(state.phase == .selectingPiece)
        #expect(state.pendingResults.map(\.result) == [.gae])
    }

    @Test
    func backDoWithAllPiecesAtHomePassesTurn() throws {
        var state = GameState(players: players)
        try throwResult(.backdho, in: &state)
        #expect(state.currentPlayer?.name == "B")
        #expect(state.phase == .readyToThrow)
    }

    @Test
    func backDoFromFirstCellKeepsPieceVisibleAtStart() throws {
        let piece = GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 1))
        var state = configuredState(piece: piece)
        try throwResult(.backdho, in: &state)
        try moveFirstPiece(in: &state)
        #expect(state.pieces.first { $0.id == piece.id }?.position == .onBoard(route: 0, index: 0))
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
        try throwResult(.dho, in: &state)
        try moveFirstPiece(in: &state)
        #expect(state.pieces.first { $0.id == piece.id }?.position == .finished)
        #expect(state.winner == nil)
        #expect(state.phase == .selectingPiece)
        #expect(state.pendingResults.map(\.result) == [.dho])
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

    @Test
    func friendlyCollisionAutomaticallyCarries() throws {
        let first = GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 2))
        let second = GamePiece(playerID: players[0].id)
        var state = GameState(players: players, pieces: [first, second] + enemyPieces())
        try throwResult(.gae, in: &state)
        try state.apply(.selectPiece(second.id))
        try state.apply(.selectDestination(try #require(state.availableDestinations.first)))
        #expect(state.phase == .movingPiece)
        #expect(state.pendingResults.isEmpty)
        let own = state.pieces.filter { $0.playerID == players[0].id }
        #expect(own.allSatisfy { $0.cell == "_4_6" })
        #expect(own[0].groupID == own[1].groupID)
        #expect(own[0].history == own[1].history)
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
    func snapshotRoundTripsAfterAutomaticCarry() throws {
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
        let before = state
        #expect(throws: GameState.RuleError.self) { try state.apply(.selectPiece(second.id)) }
        #expect(state == before)
        try state.apply(.cancelSelection)
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

    @Test
    func consecutiveBonusesCanBeSpentInAnyOrderAcrossTwoPieces() throws {
        var state = GameState(players: players)
        for result: YutResult in [.yut, .mo, .gae] { try throwResult(result, in: &state) }
        #expect(state.pendingResults.map(\.result) == [.yut, .mo, .gae])
        let results = state.pendingResults
        let own = state.currentPieces
        for (resultID, pieceID) in [(results[2].id, own[0].id), (results[1].id, own[0].id), (results[0].id, own[1].id)] {
            let result = try #require(state.pendingResults.first { $0.id == resultID })
            let piece = try #require(state.currentPieces.first { $0.id == pieceID })
            try state.apply(.selectPiece(pieceID))
            try state.apply(.selectDestination(try #require(GameBoard.destinations(for: piece, result: result.result).first)))
            #expect(state.phase == .movingPiece)
            #expect(throws: GameState.RuleError.self) { try state.apply(.selectPiece(pieceID)) }
            try state.apply(.completeMove)
        }
        #expect(state.pendingResults.isEmpty)
        #expect(state.currentPlayer?.id == players[1].id)
        #expect(state.pieces.first { $0.id == own[0].id }?.position == .onBoard(route: 0, index: 7))
        #expect(state.pieces.first { $0.id == own[1].id }?.position == .onBoard(route: 0, index: 4))
    }

    @Test
    func identicalResultsHaveDifferentIDsAndConsumedIDCannotBeReused() throws {
        var state = GameState(players: players)
        for result: YutResult in [.yut, .yut, .dho] { try throwResult(result, in: &state) }
        let first = try #require(state.pendingResults.first)
        #expect(Set(state.pendingResults.map(\.id)).count == 3)
        try moveFirstPiece(in: &state)
        #expect(state.pendingResults.map(\.result) == [.yut, .dho])
        let before = state
        #expect(throws: GameState.RuleError.self) { try state.apply(.chooseMoveResult(first.id)) }
        #expect(state == before)
    }

    @Test
    func captureKeepsUnusedResultsAndAddsConsecutiveBonusResults() throws {
        let enemy = GamePiece(playerID: players[1].id, position: .onBoard(route: 0, index: 2))
        var state = GameState(players: players, pieces: [GamePiece(playerID: players[0].id),
            GamePiece(playerID: players[0].id), enemy, GamePiece(playerID: players[1].id)])
        try throwResult(.yut, in: &state)
        let saved = try #require(state.pendingResults.first)
        try throwResult(.gae, in: &state)
        try moveFirstPiece(in: &state, using: .gae)
        #expect(state.phase == .showingBonus)
        #expect(state.pendingResults == [saved])
        #expect(state.pieces.first { $0.id == enemy.id }?.position == .home)
        try state.apply(.dismissResult)
        try throwResult(.mo, in: &state)
        #expect(state.phase == .readyToThrow)
        try throwResult(.dho, in: &state)
        #expect(state.pendingResults.map(\.result) == [.yut, .mo, .dho])
        #expect(state.pendingResults.first?.id == saved.id)
        #expect(state.currentPlayer?.id == players[0].id)
    }

    @Test
    func nakAndInterruptedBonusKeepStoredResultsAndRejectDuplicateRecord() throws {
        var state = GameState(players: players)
        try throwResult(.yut, in: &state)
        let saved = state.pendingResults
        try throwResult(.nak, in: &state)
        #expect(state.pendingResults == saved)
        for action: GameAction in [.beginThrow, .armThrow, .releaseThrow(launch: .testLaunch), .cancelThrow] {
            try state.apply(action)
        }
        #expect(state.pendingResults == saved)
        #expect(throws: GameState.RuleError.self) { try state.apply(.recordThrow(.mo)) }
        for action: GameAction in [.beginThrow, .armThrow, .releaseThrow(launch: .testLaunch), .recordThrow(.gae)] {
            try state.apply(action)
        }
        let recorded = state
        #expect(throws: GameState.RuleError.self) { try state.apply(.recordThrow(.gae)) }
        #expect(state == recorded)
        try state.apply(.dismissResult)
        #expect(state.pendingResults.map(\.result) == [.yut, .gae])
    }

    @Test
    func backDoCanBeUsedAfterAnotherStoredResultEntersBoard() throws {
        var state = GameState(players: players)
        try throwResult(.yut, in: &state)
        try throwResult(.backdho, in: &state)
        let backDo = try #require(state.pendingResults.last)
        #expect(!state.canUse(backDo))
        try moveFirstPiece(in: &state)
        #expect(state.phase == .selectingPiece)
        #expect(state.pendingResults.map(\.result) == [.backdho])
        #expect(state.canUse(backDo))
        try moveFirstPiece(in: &state)
        #expect(state.pieces.first?.position == .onBoard(route: 0, index: 3))
        #expect(state.currentPlayer?.id == players[1].id)
    }

    @Test
    func allResultDestinationsAppearAndChosenCellConsumesOneWithCarry() throws {
        let first = GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 2))
        let second = GamePiece(playerID: players[0].id)
        var state = GameState(players: players, pieces: [first, second] + enemyPieces())
        try throwResult(.yut, in: &state)
        try throwResult(.gae, in: &state)
        let results = state.pendingResults
        try state.apply(.selectPiece(second.id))
        #expect(Set(state.availableDestinations.map(\.cell)) == ["_1_6", "_4_6"])
        #expect(state.pendingResults == results)
        let destination = try #require(state.availableDestinations.first { $0.cell == "_4_6" })
        try state.apply(.selectDestination(destination))
        #expect(state.phase == .movingPiece)
        #expect(state.pendingResults == [results[0]])
        #expect(state.currentPieces[0].groupID == state.currentPieces[1].groupID)
        let moved = state
        #expect(throws: GameState.RuleError.self) { try state.apply(.selectDestination(destination)) }
        #expect(state == moved)
    }

    @Test
    func legacyCarryPromptRestoresDestinationSelectionWithoutSeparateOption() throws {
        let first = GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 2))
        let second = GamePiece(playerID: players[0].id)
        var state = GameState(players: players, pieces: [first, second] + enemyPieces())
        try throwResult(.gae, in: &state)
        try state.apply(.selectPiece(second.id))
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        object["phase"] = "promptingForCarry"
        var restored = try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(restored == state)
        try restored.apply(.selectDestination(try #require(restored.availableDestinations.first)))
        #expect(restored.currentPieces[0].groupID == restored.currentPieces[1].groupID)
        #expect(restored.pendingResults.isEmpty)
    }

    @Test
    func allCandidatesExcludeBackDoForWaitingPieceButIncludeItForBoardPiece() throws {
        let moving = GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 3))
        let waiting = GamePiece(playerID: players[0].id)
        var state = GameState(players: players, pieces: [moving, waiting] + enemyPieces())
        try throwResult(.yut, in: &state)
        try throwResult(.backdho, in: &state)
        try state.apply(.selectPiece(waiting.id))
        #expect(state.availableDestinations.map(\.cell) == ["_1_6"])
        try state.apply(.cancelSelection)
        try state.apply(.selectPiece(moving.id))
        #expect(Set(state.availableDestinations.map(\.cell)) == ["_0_4", "_4_6"])
        #expect(state.pendingResults.count == 2)
    }

    @Test
    func winClearsRemainingResultsAndPieceProgressCountsBothStackedPieces() throws {
        let group = UUID()
        let own = (0..<2).map { _ in GamePiece(playerID: players[0].id,
            position: .onBoard(route: 0, index: 19), groupID: group) }
        var state = GameState(players: players, pieces: own + enemyPieces())
        try throwResult(.yut, in: &state)
        try throwResult(.dho, in: &state)
        try moveFirstPiece(in: &state)
        #expect(state.phase == .finished)
        #expect(state.pendingResults.isEmpty)
        #expect(state.winnerID == players[0].id)
        let progress = PlayerPieceProgress(id: players[0].id, name: "A", order: 0, isCurrent: true, isLocal: true,
            positions: state.currentPieces.map(\.position))
        #expect(progress.finishedNumbers == [1, 2])
        #expect(progress.waitingNumbers.isEmpty && progress.movingNumbers.isEmpty)
        #expect(throws: GameState.RuleError.self) { try state.apply(.beginThrow) }
    }

    @Test
    func legacySnapshotRestoresSelectedMoveWithoutStoredResultFields() throws {
        var state = GameState(players: players)
        try throwResult(.gae, in: &state)
        try state.apply(.selectPiece(try #require(state.currentPieces.first).id))
        let data = try JSONEncoder().encode(state)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "pendingResults")
        object.removeValue(forKey: "selectedResultID")
        let legacy = try JSONSerialization.data(withJSONObject: object)
        var decoded = try JSONDecoder().decode(GameState.self, from: legacy)
        #expect(decoded.pendingResults.map(\.result) == [.gae])
        #expect(decoded.availableDestinations.map(\.cell) == ["_4_6"])
        try decoded.apply(.selectDestination(try #require(decoded.availableDestinations.first)))
        #expect(decoded.pendingResults.isEmpty)
    }

    @Test
    func retryingUncommittedThrowProducesIdenticalSharedResult() throws {
        var first = GameState(players: players)
        for action: GameAction in [.startPlaying, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch)] {
            try first.apply(action)
        }
        var retried = first
        try first.apply(.recordThrow(.yut))
        try retried.apply(.recordThrow(.yut))
        #expect(first == retried)
        #expect(first.pendingResults.first?.id == first.revision)
    }

    @Test
    func moAndDoShowBothDestinationsWithoutResultSelection() throws {
        var state = GameState(players: players)
        try throwResult(.mo, in: &state)
        try throwResult(.dho, in: &state)
        try state.apply(.selectPiece(try #require(state.currentPieces.first).id))
        #expect(Set(state.availableDestinations.map(\.cell)) == ["_0_6", "_5_6"])
        try state.apply(.selectDestination(try #require(state.availableDestinations.first { $0.cell == "_5_6" })))
        #expect(state.pendingResults.map(\.result) == [.mo])
        #expect(state.currentPieces.first?.position == .onBoard(route: 0, index: 1))
    }

    @Test
    func overlappingFinishRequiresChoiceAndCancelKeepsAllResults() throws {
        let piece = GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 20))
        var state = configuredState(piece: piece)
        for result: YutResult in [.yut, .mo, .dho] { try throwResult(result, in: &state) }
        let saved = state.pendingResults
        try state.apply(.selectPiece(piece.id))
        #expect(state.availableDestinations.count == 1)
        let finish = try #require(state.availableDestinations.first)
        try state.apply(.selectDestination(finish))
        #expect(state.phase == .choosingMoveResult)
        #expect(state.destinationResultChoices == saved)
        #expect(state.pieces.first == piece)
        #expect(state.pendingResults == saved)
        let snapshot = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
        #expect(snapshot == state)
        #expect(throws: GameState.RuleError.self) { try state.apply(.chooseMoveResult(-1)) }
        #expect(state == snapshot)
        try state.apply(.cancelSelection)
        #expect(state.phase == .selectingDestination)
        #expect(state.selectedPieceID == piece.id)
        #expect(state.pendingResults == saved)
        try state.apply(.selectDestination(finish))
        try state.apply(.chooseMoveResult(saved[1].id))
        #expect(state.currentPieces.first?.position == .finished)
        #expect(state.pendingResults == [saved[0], saved[2]])
        #expect(throws: GameState.RuleError.self) { try state.apply(.chooseMoveResult(saved[1].id)) }
    }

    @Test
    func doThenTwoBackDosReturnToVisibleStartAndFinishWithoutLap() throws {
        var state = GameState(players: players)
        let piece = try #require(state.currentPieces.first)
        try throwResult(.dho, in: &state)
        try moveFirstPiece(in: &state)
        try throwResult(.backdho, in: &state) // 상대의 대기 말은 빽도로 진출할 수 없어 차례 종료
        try throwResult(.backdho, in: &state)
        try moveFirstPiece(in: &state)
        let returned = try #require(state.pieces.first { $0.id == piece.id })
        #expect(returned.position == .onBoard(route: 0, index: 0))
        #expect(returned.cell == "_6_6")
        #expect(returned.history.isEmpty)
        #expect(GameBoard.destinations(for: returned, result: .dho).first?.cell == "_5_6")
        try throwResult(.backdho, in: &state)
        try throwResult(.backdho, in: &state)
        try moveFirstPiece(in: &state)
        #expect(state.pieces.first { $0.id == piece.id }?.position == .finished)
        #expect(state.winnerID == nil)
    }

    @Test
    func startCanCarryAndCaptureAndFullLapStartStillMovesBackwardNormally() throws {
        let first = GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 1))
        let atStart = GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 0))
        var state = GameState(players: players, pieces: [first, atStart] + enemyPieces())
        try throwResult(.backdho, in: &state)
        try moveFirstPiece(in: &state)
        let own = state.pieces.filter { $0.playerID == players[0].id }
        #expect(own.allSatisfy { $0.position == .onBoard(route: 0, index: 0) })
        #expect(own[0].groupID == own[1].groupID)
        try throwResult(.backdho, in: &state)
        try throwResult(.backdho, in: &state)
        try moveFirstPiece(in: &state)
        #expect(state.winnerID == players[0].id)
        let enemy = GamePiece(playerID: players[1].id, position: .onBoard(route: 0, index: 0))
        var capture = GameState(players: players, pieces: [first, GamePiece(playerID: players[0].id), enemy, GamePiece(playerID: players[1].id)])
        try throwResult(.backdho, in: &capture)
        try moveFirstPiece(in: &capture)
        #expect(capture.phase == .showingBonus)
        #expect(capture.pieces.first { $0.id == enemy.id }?.position == .home)
        let lap = GamePiece(playerID: players[0].id, position: .onBoard(route: 0, index: 20))
        #expect(GameBoard.destinations(for: lap, result: .backdho).first?.index == 19)
    }

    private func configuredState(piece: GamePiece, otherOwnPosition: PiecePosition = .home) -> GameState {
        GameState(players: players, pieces: [piece, GamePiece(playerID: players[0].id, position: otherOwnPosition)] + enemyPieces())
    }

    private func enemyPieces() -> [GamePiece] {
        [GamePiece(playerID: players[1].id), GamePiece(playerID: players[1].id)]
    }

    private func throwResult(_ result: YutResult, in state: inout GameState) throws {
        if state.phase == .movingPiece { try state.apply(.completeMove) }
        if state.phase == .preparing { try state.apply(.startPlaying) }
        try state.apply(.beginThrow)
        try state.apply(.armThrow)
        try state.apply(.releaseThrow(launch: .testLaunch))
        try state.apply(.recordThrow(result))
        try state.apply(.dismissResult)
    }

    private func moveFirstPiece(in state: inout GameState, using result: YutResult? = nil) throws {
        let piece = try #require(state.currentPieces.first { $0.position != .finished })
        try state.apply(.selectPiece(piece.id))
        let used = try #require(state.pendingResults.first { result == nil || $0.result == result })
        let cell = try #require(GameBoard.destinations(for: piece, result: used.result).first).cell
        try state.apply(.selectDestination(try #require(state.availableDestinations.first { $0.cell == cell })))
        if state.phase == .choosingMoveResult { try state.apply(.chooseMoveResult(used.id)) }
        if state.phase == .movingPiece { try state.apply(.completeMove) }
    }
}
