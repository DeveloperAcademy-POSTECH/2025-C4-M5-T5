//
//  TokenModel.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/17/25.
//
import Foundation
import RealityKit

class PieceModel {
    var id: UUID = UUID()
    var owner: PlayerModel
    var entity: Entity
    var position: String
    var routeIndex: Int = 0
    var isSelected: Bool = false

    init(owner: PlayerModel, entity: Entity, position: String = "_6_6") {
        self.owner = owner
        self.entity = entity
        self.position = position
    }
}


