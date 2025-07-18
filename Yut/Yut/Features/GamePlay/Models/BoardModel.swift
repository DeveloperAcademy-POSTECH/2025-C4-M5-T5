//
//  BoardModel.swift
//  Yut
//
//  Created by Seungeun Park on 7/18/25.
//

import ARKit

class YutBoardCell {
    let id: String
    let position: SIMD3<Float>
    var anchor: ARAnchor?
    var isCorner: Bool
    var neighbors: [YutBoardCell]
    
    init(id: String, position: SIMD3<Float>, isCorner: Bool = false) {
        self.id = id
        self.position = position
        self.isCorner = isCorner
        self.neighbors = []
    }
}
