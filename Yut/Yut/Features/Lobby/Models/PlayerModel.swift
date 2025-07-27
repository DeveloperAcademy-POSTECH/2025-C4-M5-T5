//
//  PlayerModel.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/17/25.
//

class PlayerModel {
    let name: String
    var pieces: [PieceModel]
    var sequence: Int
    
    init(name: String, sequence: Int){
        self.name = name
        self.pieces = []
        self.sequence = sequence
        
        for _ in 0..<2{
            let piece = PieceModel(owner: self)
            self.pieces.append(piece)
        }
    }
}

