//
//  BoardCellModel.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/18/25.
//

import ARKit

class BoardCellModel {
    weak var board: BoardModel?
    let row: Int
    let col: Int
    var id: String { "_\(row)_\(col)" }
    
    let position: SIMD2<Int>
    var anchor : ARAnchor?
    
    var isActive: Bool {
        board?.activeCells.contains(where: { $0 === self }) ?? false
    }
    var isBranchPoint: Bool {
        board?.branchPoints.contains(where: { $0 === self }) ?? false
    }
    var nextCandidates: [(row: Int, col: Int)] = []
    
    var isGoal: Bool {
            return row == 6 && col == 6
        }
    
    init(row: Int, col: Int, position: SIMD2<Int>, isActive: Bool, isBranchPoint: Bool) {
        self.row = row
        self.col = col
        self.position = position
    }
    
}

