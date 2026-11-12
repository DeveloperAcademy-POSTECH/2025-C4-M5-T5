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
    var gamePosition: PiecePosition = .home
    var groupID = UUID()

    /// 로비 디코딩 대신 AR 준비가 끝난 템플릿으로 시각 모델을 생성한다.
    init(id: UUID, owner: PlayerModel, entity: Entity) {
        self.id = id
        self.owner = owner
        self.entity = entity
        position = "_6_6"
        entity.name = id.uuidString
    }

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


