//
//  PlayerModel.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/17/25.
//
import RealityKit

class PlayerModel {
    let name: String
    let sequence: Int
    var pieces: [PieceModel] = []
    var pieceEntities: [Entity] = []

    static let fileNames = ["Piece1_yellow", "Piece2_jade", "Piece3_blue", "Piece4_red"]

    init(name: String, sequence: Int, entities: [Entity]) {
        self.name = name
        self.sequence = sequence
        self.pieceEntities = entities

        for i in 0..<2 {
            let piece = PieceModel(owner: self, entity: entities[i])
            pieces.append(piece)
        }
    }

    static func load(name: String, sequence: Int) async -> PlayerModel {
        var loadedEntities: [Entity] = []

        for file in fileNames {
            do {
                let entity = try await Entity(named: file)
                loadedEntities.append(entity)
            } catch {
                print("'\(file)' 로딩 실패:", error)
            }
        }

        return PlayerModel(name: name, sequence: sequence, entities: loadedEntities)
    }
}
