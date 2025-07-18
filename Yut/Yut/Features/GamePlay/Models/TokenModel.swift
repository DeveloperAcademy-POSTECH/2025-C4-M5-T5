//
//  TokenModel.swift
//  Yut
//
//  Created by Seungeun Park on 7/18/25.
//

import ARKit

class YutToken {
    var id : UUID = UUID()
    var positionIndex: Int = 0
    var anchor: ARAnchor?
    var isActive: Bool = false
    var owner: YutPlayer
    
    init(owner: YutPlayer){
        self.owner = owner
    }
}
