//
//  Move.swift
//  Yut
//
//  Created by Seungeun Park on 7/21/25.
//

import simd

struct MoveResult {
    let piece: PieceModel
    let cell: BoardCellModel
    let id: String
    var didCapture: Bool = false
    var didCarry: Bool = false
    var didGoal: Bool = false
}

extension BoardModel {
    func move(from cell: BoardCellModel, steps: Int) -> BoardCellModel? {
        var current = cell
        for _ in 0..<steps {
            guard let nextCoords = current.nextCandidates.first,
                  let nextCell = cellAt(row: nextCoords.row, col: nextCoords.col) else {
                return nil
            }
            current = nextCell
        }
        return current
    }

    func cellAt(row: Int, col: Int) -> BoardCellModel? {
        return cells.first { $0.row == row && $0.col == col }
    }
}
