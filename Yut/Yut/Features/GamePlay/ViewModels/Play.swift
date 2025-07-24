//
//  GamaManager.swift
//  Yut
//
//  Created by Seungeun Park on 7/21/25.
//

import Foundation

enum YutResult: Int {
    case backdho = -1, dho = 1, gae = 2, geol = 3, yut = 4, mo = 5

    var steps: Int { rawValue }
    var isExtraTurn: Bool { self == .yut || self == .mo }
}


class GameManager: ObservableObject {
    static let shared = GameManager()

    @Published var lastMoveResult: Result?
    @Published var gameEnded: Bool = false
    
    var board: BoardModel = BoardModel()
    
    var players: [PlayerModel] = [
        PlayerModel(name: "HappyJay", sequence: 0),
        PlayerModel(name: "Noter", sequence: 1),
        PlayerModel(name: "Hidy", sequence: 2),
        PlayerModel(name: "Sena", sequence: 3)
    ]
    var currentPlayerIndex: Int = 0
    var yutResult: YutResult?

    var currentPlayer: PlayerModel {
        players[currentPlayerIndex]
    }

    func nextTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
    }

    func applyYutResult(routeIndex: Int = 0) {
        guard let yutResult = yutResult else { return }
        guard let selectedPiece = currentPlayer.pieces.first(where: { $0.isSeleted }) else {
            print("선택된 말이 없습니다.")
            return
        }

        if let finalresult = board.move(piece: selectedPiece, steps: yutResult.steps, routeIndex: routeIndex) {
            selectedPiece.currentCell = board.cells.first(where: { $0.id == finalresult.cell.id}) // 혹은 nextCell 참조 보존 시 직접 할당

            lastMoveResult = finalresult.cellresult
            if finalresult.cell.id == "end" {
                checkIfGameEnded()
            }

            if let cellResult = finalresult.cellresult {
                if cellResult.didCapture {
                    print("상대 말을 잡음")
                }

                if cellResult.didCarry {
                    print("말 업음")
                }
            }

            if yutResult.isExtraTurn {
                print("윷/모 한 번 더 던지기")
                // UI에서 다시 던지게 유도
            } else {
                nextTurn()
            }
        }
    }

    private func checkIfGameEnded() {
        let allPiecesReached = currentPlayer.pieces.allSatisfy { $0.currentCell?.id == "end" || $0.currentCell == nil }
        if allPiecesReached {
            gameEnded = true
            print("🎉 \(currentPlayer.name) 님이 게임에서 승리했습니다!")
        }
    }
}
