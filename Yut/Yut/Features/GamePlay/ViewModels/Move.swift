//
//  Move.swift
//  Yut
//
//  Created by Seungeun Park on 7/21/25.
//

import simd

struct MoveResult {
    let cell: BoardCellModel
    let id: String
}

enum Direction {
    case up, left, down, right
    case diagonalRight, diagonalLeft

    var offset: SIMD3<Int> {
        switch self {
        case .up: return SIMD3(-1, 0, 0)
        case .left: return SIMD3(0, -1, 0)
        case .down: return SIMD3(1, 0, 0)
        case .right: return SIMD3(0, 1, 0)
        case .diagonalLeft: return SIMD3(1, -1, 0)
        case .diagonalRight: return SIMD3(1, 1, 0)

        }
    }
}

extension BoardModel {
    func move(from cell: BoardCellModel, direction: Direction, steps: Int) -> MoveResult? {
            let offset = direction.offset &* steps
            let newRow = cell.row + offset.x
            let newCol = cell.col + offset.y

            guard (0..<size).contains(newRow), (0..<size).contains(newCol),
                  let nextCell = cellAt(row: newRow, col: newCol) else {
                return nil
            }

            return MoveResult(cell: nextCell, id: nextCell.id)
        }

    func cellAt(row: Int, col: Int) -> BoardCellModel? {
        return cells.first { $0.row == row && $0.col == col }
    }
}
