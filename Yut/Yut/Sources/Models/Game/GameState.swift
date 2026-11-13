import Foundation

/// 차례, 말의 이동·업기·잡기와 승패를 계산하는 값 타입 상태다.
/// 전송·타이머·AR 자원과 분리하고, 유효한 명령 하나마다 `revision`을 한 번 증가시킨다.
struct GameState: Codable, Equatable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case id, players, pieces, currentPlayerIndex, phase, latestResult, pendingResults, pendingDestinationCell
        case selectedPieceID, winnerID, revision, throwLaunch
    }

    enum RuleError: Error, LocalizedError {
        case invalidAction
        case invalidPiece
        case invalidDestination

        var errorDescription: String? { "현재 게임 상태에서는 이 동작을 할 수 없습니다." }
    }

    let id: UUID
    private(set) var players: [GamePlayer]
    private(set) var pieces: [GamePiece]
    private(set) var currentPlayerIndex: Int
    private(set) var phase: MatchPhase = .preparing
    private(set) var latestResult: YutResult?
    private(set) var pendingResults: [StoredYutResult] = []
    /// 같은 지점에 도달하는 서로 다른 결과가 있을 때만 사용 결과를 확인한다.
    private(set) var pendingDestinationCell: String?
    private(set) var selectedPieceID: UUID?
    private(set) var winnerID: UUID?
    private(set) var revision = 0
    private(set) var throwLaunch: YutThrowLaunch?

    var currentPlayer: GamePlayer? {
        guard players.indices.contains(currentPlayerIndex) else { return nil }
        return players[currentPlayerIndex]
    }

    var winner: GamePlayer? { players.first { $0.id == winnerID } }
    var selectedPiece: GamePiece? { pieces.first { $0.id == selectedPieceID } }
    var currentPieces: [GamePiece] { pieces.filter { $0.playerID == currentPlayer?.id } }
    var isSelectingMove: Bool { phase == .selectingPiece || phase == .selectingDestination }
    var canPlaceNewPiece: Bool {
        phase == .selectingPiece && currentPieces.contains { $0.position == .home && canMove($0) }
    }
    var availableDestinations: [MoveDestination] {
        guard [.selectingDestination, .choosingMoveResult].contains(phase), let selectedPiece else { return [] }
        var cells: Set<String> = []
        return pendingResults.flatMap { GameBoard.destinations(for: selectedPiece, result: $0.result) }
            .filter { cells.insert($0.cell).inserted }
    }
    var destinationResultChoices: [StoredYutResult] {
        guard phase == .choosingMoveResult, let pendingDestinationCell else { return [] }
        return results(reaching: pendingDestinationCell)
    }

    func canMove(_ piece: GamePiece) -> Bool {
        pendingResults.contains { !GameBoard.destinations(for: piece, result: $0.result).isEmpty }
    }

    /// 같은 결과가 여러 개면 먼저 보유한 한 건을 쓴다. 서로 다른 결과만 선택 대상으로 남긴다.
    private func results(reaching cell: String) -> [StoredYutResult] {
        guard let selectedPiece else { return [] }
        var kinds: Set<YutResult> = []
        return pendingResults.filter {
            GameBoard.destinations(for: selectedPiece, result: $0.result).contains { $0.cell == cell }
                && kinds.insert($0.result).inserted
        }
    }

    func canUse(_ result: StoredYutResult) -> Bool {
        currentPieces.contains { !GameBoard.destinations(for: $0, result: result.result).isEmpty }
    }

    init(id: UUID = UUID(), players: [GamePlayer], pieces: [GamePiece]? = nil, currentPlayerIndex: Int = 0) {
        self.id = id
        self.players = players.sorted { $0.order < $1.order }
        self.pieces = pieces ?? self.players.flatMap { player in
            [GamePiece(playerID: player.id), GamePiece(playerID: player.id)]
        }
        self.currentPlayerIndex = currentPlayerIndex
    }

    /// 결과 목록이 없던 스냅샷의 이동 대기 결과도 해당 상태 버전으로 복원한다.
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        players = try values.decode([GamePlayer].self, forKey: .players)
        pieces = try values.decode([GamePiece].self, forKey: .pieces)
        currentPlayerIndex = try values.decode(Int.self, forKey: .currentPlayerIndex)
        let phaseName = try values.decode(String.self, forKey: .phase)
        // 이전 업기 선택 대기 스냅샷은 목적지를 다시 선택해 자동 업기를 확정할 수 있게 복원한다.
        guard let restoredPhase = MatchPhase(rawValue: phaseName == "promptingForCarry" ? "selectingDestination" : phaseName) else {
            throw DecodingError.dataCorruptedError(forKey: .phase, in: values, debugDescription: "Unknown match phase")
        }
        phase = restoredPhase
        latestResult = try values.decodeIfPresent(YutResult.self, forKey: .latestResult)
        selectedPieceID = try values.decodeIfPresent(UUID.self, forKey: .selectedPieceID)
        winnerID = try values.decodeIfPresent(UUID.self, forKey: .winnerID)
        revision = try values.decode(Int.self, forKey: .revision)
        throwLaunch = try values.decodeIfPresent(YutThrowLaunch.self, forKey: .throwLaunch)
        if let results = try values.decodeIfPresent([StoredYutResult].self, forKey: .pendingResults) {
            pendingResults = results
        } else if let latestResult, latestResult != .nak,
                  [.showingResult, .selectingPiece, .selectingDestination].contains(phase) {
            pendingResults = [StoredYutResult(id: revision, result: latestResult)]
        }
        pendingDestinationCell = try values.decodeIfPresent(String.self, forKey: .pendingDestinationCell)
    }

    // MARK: - 상태 전이

    /// 복사본에서 명령 전체를 검증한 뒤 성공한 상태만 반영한다.
    /// - Throws: 단계·말·목적지가 유효하지 않으면 `RuleError`를 던지며 원래 상태와 버전을 유지한다.
    mutating func apply(_ action: GameAction) throws {
        var next = self
        try next.perform(action)
        next.revision += 1
        self = next
    }

    private mutating func perform(_ action: GameAction) throws {
        switch action {
        case .startPlaying:
            guard phase == .preparing, players.count >= 2 else { throw RuleError.invalidAction }
            phase = .readyToThrow
        case .beginThrow:
            guard phase == .readyToThrow else { throw RuleError.invalidAction }
            latestResult = nil
            pendingDestinationCell = nil
            throwLaunch = nil
            phase = .gathering
        case .armThrow:
            guard phase == .gathering else { throw RuleError.invalidAction }
            phase = .waitingForShake
        case .releaseThrow(let launch):
            guard phase == .waitingForShake, launch.isValid else { throw RuleError.invalidAction }
            throwLaunch = launch
            phase = .throwing
        case .recordThrow(let result):
            guard phase == .throwing else { throw RuleError.invalidAction }
            latestResult = result
            if result != .nak { pendingResults.append(StoredYutResult(id: revision + 1, result: result)) }
            phase = .showingResult
        case .dismissResult:
            guard phase == .showingResult || phase == .showingBonus else { throw RuleError.invalidAction }
            if phase == .showingBonus || latestResult == .nak || latestResult?.grantsAnotherThrow == true {
                latestResult = nil
                phase = .readyToThrow
            } else {
                continueMovingOrAdvanceTurn()
            }
        case .selectPiece(let id):
            guard phase == .selectingPiece else { throw RuleError.invalidAction }
            guard let piece = pieces.first(where: { $0.id == id }), piece.playerID == currentPlayer?.id,
                  canMove(piece) else {
                throw RuleError.invalidPiece
            }
            selectedPieceID = id
            phase = .selectingDestination
        case .selectDestination(let destination):
            guard phase == .selectingDestination, availableDestinations.contains(destination) else {
                throw RuleError.invalidDestination
            }
            let choices = results(reaching: destination.cell)
            if choices.count > 1 {
                pendingDestinationCell = destination.cell
                phase = .choosingMoveResult
            } else if let result = choices.first {
                try move(to: destination.cell, using: result)
            } else { throw RuleError.invalidDestination }
        case .chooseMoveResult(let id):
            guard phase == .choosingMoveResult, let cell = pendingDestinationCell,
                  let result = destinationResultChoices.first(where: { $0.id == id }) else {
                throw RuleError.invalidAction
            }
            try move(to: cell, using: result)
        case .cancelSelection:
            if phase == .choosingMoveResult {
                pendingDestinationCell = nil
                phase = .selectingDestination
            } else {
                guard phase == .selectingDestination else { throw RuleError.invalidAction }
                selectedPieceID = nil
                phase = .selectingPiece
            }
        case .completeMove:
            guard phase == .movingPiece else { throw RuleError.invalidAction }
            continueMovingOrAdvanceTurn()
        case .cancelThrow:
            guard [.gathering, .waitingForShake, .throwing].contains(phase) else { throw RuleError.invalidAction }
            selectedPieceID = nil
            throwLaunch = nil
            latestResult = nil
            pendingDestinationCell = nil
            phase = .readyToThrow
        }
    }

    // MARK: - 이동 결과와 차례

    /// 선택한 업힌 그룹을 함께 이동하고 잡기·업기·완주 결과를 한 번에 반영한다.
    /// - Throws: 기준이 되는 선택 말이 없으면 `RuleError.invalidPiece`.
    private mutating func move(to cell: String, using result: StoredYutResult) throws {
        guard let selectedPiece,
              let resultIndex = pendingResults.firstIndex(where: { $0.id == result.id }),
              let destination = GameBoard.destinations(for: selectedPiece, result: result.result).first(where: { $0.cell == cell }) else {
            throw RuleError.invalidPiece
        }
        let movingIDs = Set(pieces.filter { $0.groupID == selectedPiece.groupID && $0.playerID == selectedPiece.playerID }.map(\.id))
        let capturedIDs = Set(pieces.filter {
            $0.cell != nil && $0.cell == destination.cell && $0.playerID != selectedPiece.playerID
        }.map(\.id))
        let newPosition: PiecePosition = destination.isFinish ? .finished : .onBoard(route: destination.route, index: destination.index)
        for index in pieces.indices {
            if capturedIDs.contains(pieces[index].id) {
                pieces[index].position = .home
                pieces[index].groupID = pieces[index].id
                pieces[index].history = []
            } else if movingIDs.contains(pieces[index].id) {
                pieces[index].position = newPosition
                if result.result == .backdho {
                    if !pieces[index].history.isEmpty { pieces[index].history.removeLast() }
                } else {
                    pieces[index].history += destination.traversedPositions
                }
            }
        }
        if !destination.isFinish {
            // 같은 칸의 같은 편 말은 반드시 업는다. 이후 어느 말을 골라도 같은 빽도 이력을 사용한다.
            let history = pieces.first { $0.id == selectedPiece.id }?.history ?? []
            for index in pieces.indices where pieces[index].playerID == selectedPiece.playerID && pieces[index].cell == destination.cell {
                pieces[index].groupID = selectedPiece.groupID
                pieces[index].position = newPosition
                pieces[index].history = history
            }
        }
        selectedPieceID = nil
        pendingResults.remove(at: resultIndex)
        self.pendingDestinationCell = nil
        latestResult = nil
        if pieces.filter({ $0.playerID == selectedPiece.playerID }).allSatisfy({ $0.position == .finished }) {
            winnerID = selectedPiece.playerID
            phase = .finished
            pendingResults.removeAll()
        } else if !capturedIDs.isEmpty {
            phase = .showingBonus
        } else {
            phase = .movingPiece
        }
    }

    private mutating func continueMovingOrAdvanceTurn() {
        selectedPieceID = nil
        if pendingResults.contains(where: canUse) {
            pendingDestinationCell = nil
            phase = .selectingPiece
        } else {
            // 다른 결과로 진출할 수 있으면 빽도를 보존하고, 모두 이동 불가일 때 차례를 끝낸다.
            advanceTurn()
        }
    }

    private mutating func advanceTurn() {
        guard !players.isEmpty else { return }
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        latestResult = nil
        pendingResults.removeAll()
        pendingDestinationCell = nil
        selectedPieceID = nil
        phase = .readyToThrow
    }
}
