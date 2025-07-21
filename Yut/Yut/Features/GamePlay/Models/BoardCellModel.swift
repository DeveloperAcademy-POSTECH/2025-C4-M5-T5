//
//  BoardCellModel.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/18/25.
//

import ARKit

class YutBoardCell {
    let row: Int
    let col: Int
    let position: SIMD3<Float>
    let isActive: Bool
    let isBranchPoint: Bool
    var nextCandidates: [(row: Int, col: Int)] = []
    
    init(row: Int, col: Int, position: SIMD3<Float>, isActive: Bool, isBranchPoint: Bool) {
        self.row = row
        self.col = col
        self.position = position
        self.isActive = isActive
        self.isBranchPoint = isBranchPoint
    }
}

