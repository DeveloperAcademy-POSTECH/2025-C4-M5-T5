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
    var id: String { "\(row),\(col)" }
    
    let position: SIMD3<Int>
    var anchor : ARAnchor?
    
    var isActive: Bool {
        board?.activeCells.contains(where: { $0 === self }) ?? false
    }
    var isBranchPoint: Bool {
        board?.branchPoints.contains(where: { $0 === self }) ?? false
    }
    var nextCandidates: [(row: Int, col: Int)] = []
    
    init(row: Int, col: Int, position: SIMD3<Int>, isActive: Bool, isBranchPoint: Bool) {
        self.row = row
        self.col = col
        self.position = position
    }
}

