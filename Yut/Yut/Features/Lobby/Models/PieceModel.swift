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

    // 모델 로딩에 실패하면 객체 생성 자체를 실패
    init?(owner: PlayerModel, position: String = "_6_6") {
        self.owner = owner
        self.position = position
        do {
            let tokenEntity: Entity = try ModelEntity.load(named: owner.pieceEntity)
            tokenEntity.name = self.id.uuidString
            self.entity = tokenEntity
        } catch {
            print("모델 로딩 실패: \(error)")
            return nil
        }
    }
}


