//
//  PlayerModel.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/17/25.
//

class YutPlayer {
    let name: String
    var tokens: [Piece]
    
    init(name: String){
        self.name = name
        self.tokens = []
        
        for _ in 0..<2{
            let token = Piece(owner: self)
            self.tokens.append(token)
        }
    }
}

