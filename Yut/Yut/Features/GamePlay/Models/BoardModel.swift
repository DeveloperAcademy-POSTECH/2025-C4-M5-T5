//
//  BoardModel.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/18/25.
//

import ARKit

class BoardModel {
    let size = 7
    var cells: [YutBoardCell] = []

    init() {
        for row in 0..<size {
            for col in 0..<size {
                let position = SIMD3<Float>(Float(row), 0, Float(col))
                let isEdge = row == 0 || row == size - 1 || col == 0 || col == size - 1
                let isDiagonal = row == col || row + col == size - 1
                let isExcluded = (row == 3 && col == 0) || (row == 0 && col == 3) ||
                                 (row == 3 && col == 6) || (row == 6 && col == 3)
                
                let isActive = (isEdge || isDiagonal) && !isExcluded

                // 분기점 3군데
                let isBranchPoint = (row == 0 && col == 0) ||
                                    (row == 0 && col == 6) ||
                                    (row == 3 && col == 3)

                let cell = YutBoardCell(
                    row: row,
                    col: col,
                    position: position,
                    isActive: isActive,
                    isBranchPoint: isBranchPoint
                )

                if isBranchPoint {
                    switch (row, col) {
                    case (0, 0):
                        cell.nextCandidates = [(1, 0), (1, 1)]
                    case (0, 6):
                        cell.nextCandidates = [(0, 5), (1, 5)] // 아래 or 대각선 왼쪽 아래
                    case (3, 3):
                        cell.nextCandidates = [(4, 2), (4, 4)]
                    default:
                        break
                    }
                }

                cells.append(cell)
            }
        }
    }
}

