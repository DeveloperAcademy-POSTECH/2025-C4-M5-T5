import Foundation

/// 차례, 말의 이동·업기·잡기와 승패를 계산하는 값 타입 상태다.
/// 전송·타이머·AR 자원과 분리하고, 유효한 명령 하나마다 `revision`을 한 번 증가시킨다.
struct GameState: Codable, Equatable, Sendable {
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
    private(set) var selectedPieceID: UUID?
    /// 같은 편의 다른 그룹과 만났을 때 업기 선택이 끝날 때까지 보류하는 목적지다.
    private(set) var pendingDestination: MoveDestination?
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
    var canPlaceNewPiece: Bool {
        guard let result = latestResult else { return false }
        return currentPieces.contains { $0.position == .home && !GameBoard.destinations(for: $0, result: result).isEmpty }
    }
    var availableDestinations: [MoveDestination] {
        guard let selectedPiece, let latestResult else { return [] }
        return GameBoard.destinations(for: selectedPiece, result: latestResult)
    }

    init(id: UUID = UUID(), players: [GamePlayer], pieces: [GamePiece]? = nil, currentPlayerIndex: Int = 0) {
        self.id = id
        self.players = players.sorted { $0.order < $1.order }
        self.pieces = pieces ?? self.players.flatMap { player in
            [GamePiece(playerID: player.id), GamePiece(playerID: player.id)]
        }
        self.currentPlayerIndex = currentPlayerIndex
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
            phase = .showingResult
        case .dismissResult:
            // 낙·추가 던지기는 차례를 유지하고, 이동 가능한 말이 없는 빽도는 차례를 넘긴다.
            guard phase == .showingResult || phase == .showingBonus else { throw RuleError.invalidAction }
            if phase == .showingBonus || latestResult == .nak {
                latestResult = nil
                phase = .readyToThrow
            } else if let latestResult,
                      currentPieces.contains(where: { !GameBoard.destinations(for: $0, result: latestResult).isEmpty }) {
                phase = .selectingPiece
            } else {
                advanceTurn()
            }
        case .selectPiece(let id):
            guard phase == .selectingPiece || phase == .selectingDestination else { throw RuleError.invalidAction }
            guard let piece = pieces.first(where: { $0.id == id }), piece.playerID == currentPlayer?.id,
                  let latestResult, !GameBoard.destinations(for: piece, result: latestResult).isEmpty else {
                throw RuleError.invalidPiece
            }
            selectedPieceID = id
            phase = .selectingDestination
        case .selectDestination(let destination):
            guard phase == .selectingDestination, availableDestinations.contains(destination), let selectedPiece else {
                throw RuleError.invalidDestination
            }
            let friendAtDestination = pieces.contains {
                $0.cell != nil && $0.cell == destination.cell && $0.playerID == selectedPiece.playerID && $0.groupID != selectedPiece.groupID
            }
            if friendAtDestination {
                pendingDestination = destination
                phase = .promptingForCarry
            } else {
                try move(to: destination, carry: false)
            }
        case .resolveCarry(let shouldCarry):
            guard phase == .promptingForCarry, let pendingDestination else { throw RuleError.invalidAction }
            try move(to: pendingDestination, carry: shouldCarry)
        case .cancelSelection:
            guard phase == .selectingDestination else { throw RuleError.invalidAction }
            selectedPieceID = nil
            phase = .selectingPiece
        case .cancelThrow:
            guard [.gathering, .waitingForShake, .throwing].contains(phase) else { throw RuleError.invalidAction }
            selectedPieceID = nil
            pendingDestination = nil
            throwLaunch = nil
            latestResult = nil
            phase = .readyToThrow
        }
    }

    // MARK: - 이동 결과와 차례

    /// 선택한 업힌 그룹을 함께 이동하고 잡기·업기·완주 결과를 한 번에 반영한다.
    /// - Parameter carry: 목적지의 같은 편 말까지 그룹과 이동 이력을 합칠지 여부.
    /// - Throws: 기준이 되는 선택 말이 없으면 `RuleError.invalidPiece`.
    private mutating func move(to destination: MoveDestination, carry: Bool) throws {
        guard let selectedPiece else { throw RuleError.invalidPiece }
        let movingIDs = Set(pieces.filter { $0.groupID == selectedPiece.groupID && $0.playerID == selectedPiece.playerID }.map(\.id))
        let capturedIDs = Set(pieces.filter {
            $0.cell != nil && $0.cell == destination.cell && $0.playerID != selectedPiece.playerID
        }.map(\.id))
        let newPosition: PiecePosition = destination.isFinish ? .finished : (
            destination.isHome ? .home : .onBoard(route: destination.route, index: destination.index)
        )
        for index in pieces.indices {
            if capturedIDs.contains(pieces[index].id) {
                pieces[index].position = .home
                pieces[index].groupID = pieces[index].id
                pieces[index].history = []
            } else if movingIDs.contains(pieces[index].id) {
                pieces[index].position = newPosition
                if latestResult == .backdho {
                    if !pieces[index].history.isEmpty { pieces[index].history.removeLast() }
                } else {
                    pieces[index].history += destination.traversedPositions
                }
                if destination.isHome { pieces[index].history = [] }
                if destination.isHome { pieces[index].groupID = pieces[index].id }
            }
        }
        if carry {
            // 업힌 뒤에는 어느 말을 선택해도 같은 빽도 경로를 사용하도록 이력을 통일한다.
            let history = pieces.first { $0.id == selectedPiece.id }?.history ?? []
            for index in pieces.indices where pieces[index].playerID == selectedPiece.playerID && pieces[index].cell == destination.cell {
                pieces[index].groupID = selectedPiece.groupID
                pieces[index].position = newPosition
                pieces[index].history = history
            }
        }
        selectedPieceID = nil
        pendingDestination = nil
        if pieces.filter({ $0.playerID == selectedPiece.playerID }).allSatisfy({ $0.position == .finished }) {
            winnerID = selectedPiece.playerID
            phase = .finished
        } else if !capturedIDs.isEmpty || latestResult?.grantsAnotherThrow == true {
            // 잡기와 윷·모가 함께 발생해도 추가 던지기 단계는 한 번만 연다.
            latestResult = nil
            phase = .showingBonus
        } else {
            advanceTurn()
        }
    }

    private mutating func advanceTurn() {
        guard !players.isEmpty else { return }
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        latestResult = nil
        selectedPieceID = nil
        phase = .readyToThrow
    }
}
