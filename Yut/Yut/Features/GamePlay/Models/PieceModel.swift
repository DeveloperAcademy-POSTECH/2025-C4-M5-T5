//
//  TokenModel.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/17/25.
//

import ARKit

class PieceModel {
    var id : UUID = UUID()
    var currentCell: BoardCellModel?
    var anchor: ARAnchor?
    var isSeleted: Bool = false
    var firstStart: Bool
    var owner: PlayerModel
    var carriedPiece: PieceModel?
    var isGoalReached: Bool = false
    
    init(owner: PlayerModel, firstStart: Bool){
        self.owner = owner
        self.firstStart = firstStart
    }
    
    var isCarrying: Bool {
            return carriedPiece != nil
        }
    
}


