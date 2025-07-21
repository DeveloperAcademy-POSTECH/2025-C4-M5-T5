//
//  PlayerModel.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/17/25.
//

class PlayerModel {
    let name: String
    var tokens: [PieceModel]
    var sequence: Int
    
    init(name: String, sequence: Int){
        self.name = name
        self.tokens = []
        self.sequence = sequence
        
        for _ in 0..<2{
            let token = PieceModel(owner: self)
            self.tokens.append(token)
        }
    }
}

