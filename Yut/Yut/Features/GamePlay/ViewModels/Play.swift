//
//  Play.swift
//  Yut
//
//  Created by Seungeun Park on 7/21/25.
//

import Foundation
import ARKit

enum YutResult: Int {
    case backdho = -1
    case dho = 1
    case gae = 2
    case geol = 3
    case yut = 4
    case mo = 5

    var steps: Int { self.rawValue }

    var isExtraTurn: Bool {
        return self == .yut || self == .mo
    }
}

let startCell = BoardCellModel(row: 6, col: 6, position: SIMD2<Int>(6, 6), isActive: true, isBranchPoint: false)

let players = (1...4).map { i in
    PlayerModel(name: "Player\(i)", sequence: i)
}

let gameManager = GameManager(players: players)

class GameManager {
    @Published var lastMoveResult: MoveResult?

    var players: [PlayerModel]
    var currentPlayerIndex = 0
    var playerTurn: PlayerModel { players[currentPlayerIndex] }
    var YutResult: YutResult?

    init(players: [PlayerModel]) {
        self.players = players
    }

    func piecesAvailableToSelect() -> [PieceModel] {
        return playerTurn.pieces.filter { $0.carriedPiece == nil }
    }

    private func allOtherPlayersPieces() -> [PieceModel] {
        return players
            .filter { $0 !== playerTurn }
            .flatMap { $0.pieces }
    }

    func applyYutResult(_ result: YutResult, for piece: PieceModel, on board: BoardModel) {
        self.YutResult = result

        guard piecesAvailableToSelect().contains(where: { $0 === piece }),
              let startCell = piece.currentCell else { return }

        let candidates = startCell.nextCandidates
        if candidates.count > 1 {
            // 수정해야함
            return
        }

        guard let destinationCell = board.move(from: startCell, steps: result.steps) else { return }
        piece.currentCell = destinationCell

        var moveResult = MoveResult(piece: piece, cell: destinationCell, id: destinationCell.id)

        // 상대 말 잡기
        for token in allOtherPlayersPieces() {
            if token.currentCell === destinationCell {
                token.currentCell = startCell
                token.firstStart = true
                moveResult.didCapture = true
            }
        }

        // 내 말 업기
        if let sameOwner = playerTurn.pieces.first(where: { $0 !== piece && $0.currentCell === destinationCell }) {
            piece.carriedPiece = sameOwner
            moveResult.didCarry = true
        }

        // 골 도착 판별
        if destinationCell.isGoal {
            piece.isGoalReached = true
            moveResult.didGoal = true
        }

        // 결과 저장
        lastMoveResult = moveResult

        // 턴 넘기기
        if !result.isExtraTurn {
            currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        }
    }
}
