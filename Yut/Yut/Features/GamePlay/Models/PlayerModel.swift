//
//  PlayerModel.swift
//  Yut
//
//  Created by Seungeun Park on 7/18/25.
//

class YutPlayer {
    let name: String
    var tokens: [YutToken]
    
    init(name: String){
        self.name = name
        self.tokens = []
        
        for _ in 0..<2{
            let token = YutToken(owner: self)
            self.tokens.append(token)
        }
    }
}
