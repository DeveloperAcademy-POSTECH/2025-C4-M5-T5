//
//  TokenModel.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/17/25.
//

import ARKit

class Piece {
    var id : UUID = UUID()
    var currentCell: YutBoardCell?
    var anchor: ARAnchor?
    var isSeleted: Bool = false
    var owner: YutPlayer
    var carriedPiece: Piece?
    var isGoalReached: Bool = false
    
    init(owner: YutPlayer){
        self.owner = owner
    }
    
    var isCarrying: Bool {
            return carriedPiece != nil
        }
}


