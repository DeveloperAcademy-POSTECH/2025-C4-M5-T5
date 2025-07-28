//
//  TokenManager.swift
//  Yut
//
//  Created by yunsly on 7/27/25.
//

import Foundation
import RealityKit
import ARKit

final class PieceManager {
    
    weak var boardAnchor: AnchorEntity? // 윷판 앵커
    var pieceEntities: [Entity] = []
    
    private var originalMaterials: [ModelEntity: RealityFoundation.Material] = [:]
    
    
    func placeNewPiece(on tileName: String) {
        guard let boardEntity = boardAnchor?.children.first,
              let tileEntity = boardEntity.findEntity(named: tileName) else {
            print("❌ \(tileName) 타일을 찾을 수 없습니다.")
            return
        }
        
        do {
            let piece = try ModelEntity.load(named: "Piece1_yellow.usdz")
            piece.generateCollisionShapes(recursive: true)
            piece.scale = [0.3, 8.0, 0.3]
            piece.name = "yut_piece_\(pieceEntities.count)"
            piece.position = [0, 0.2, 0]
            
            tileEntity.addChild(piece)
            pieceEntities.append(piece)
            print("✅ \(tileName)에 새로운 말 배치 완료")
        } catch {
            print("❌ 말 로드 실패: \(error)")
        }
    }
    
    func movePiece(piece: Entity, to tileName: String) {
        guard let boardEntity = boardAnchor?.children.first,
              let destinationTile = boardEntity.findEntity(named: tileName) else {
            print("❌ 목적지 \(tileName) 타일을 찾을 수 없습니다.")
            return
        }
        
        var destinationPosition = destinationTile.position(relativeTo: nil)
        destinationPosition.y += 0.02
        
        var transform = Transform(matrix: piece.transformMatrix(relativeTo: nil))
        transform.translation = destinationPosition
        
        piece.move(
            to: transform,
            relativeTo: nil,
            duration: 0.5,
            timingFunction: .easeInOut
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            piece.setParent(destinationTile)
            piece.setPosition([0, 0.02, 0], relativeTo: destinationTile)
            print("✅ \(piece.name) 이동 완료 → \(tileName)")
        }
    }
    
    // MARK: - Highlighting
    
    // ✨ 1. 기존 함수를 '타일' 하이라이트 전용으로 이름을 명확하게 변경
    func highlightTiles(named tileNames: [String]) {
        guard let boardEntity = boardAnchor?.children.first else {
            print("❌ 윷판 엔티티 없음")
            return
        }
        
        clearAllHighlights() // 이전에 있던 모든 하이라이트 제거
        
        for name in tileNames {
            guard let tile = boardEntity.findEntity(named: name) as? ModelEntity else { continue }
            applyHighlight(to: tile)
        }
    }
    
    // ✨ 2. 제안하신 '말'들을 하이라이트하는 새로운 함수
    func highlightMovablePieces(_ pieces: [PieceModel]) {
        clearAllHighlights() // 이전에 있던 모든 하이라이트 제거
        
        for piece in pieces {
            // PieceModel에서 AR Entity를 직접 가져옵니다.
            guard let pieceEntity = piece.entity as? ModelEntity else { continue }
            applyHighlight(to: pieceEntity)
        }
    }
    
    
    // ✨ 3. 하이라이트를 적용하는 로직을 별도 함수로 분리 (코드 중복 제거)
    private func applyHighlight(to entity: ModelEntity) {
        guard let model = entity.model else { return }
        
        // 원래 머티리얼을 딕셔너리에 저장
        if let material = model.materials.first {
            originalMaterials[entity] = material
        }
        
        // 하이라이트 머티리얼 생성 및 적용
        var highlightMaterial = UnlitMaterial()
        highlightMaterial.color = .init(tint: .yellow.withAlphaComponent(0.8))
        
        var newModel = model
        newModel.materials = [highlightMaterial]
        entity.model = newModel
    }
    
    // ✨ 4. 모든 하이라이트를 원래대로 되돌리는 함수
    func clearAllHighlights() {
        // 딕셔너리에 저장된 모든 엔티티를 순회하며 원래 머티리얼로 복원
        for (entity, originalMaterial) in originalMaterials {
            entity.model?.materials = [originalMaterial]
        }
        originalMaterials.removeAll()
    }
    
    // ✨ 판 밖에 있던 말을 처음으로 AR 씬에 추가하는 함수
        func placePieceOnBoard(piece: PieceModel, on tileName: String) {
            guard let destinationTile = boardAnchor?.findEntity(named: tileName) else {
                print("❌ 목적지 \(tileName) 타일을 찾을 수 없습니다.")
                return
            }
            
            
        
            
            
            
            
            let pieceEntity = piece.entity // PlayerModel.load()가 이미 로드해 둔 엔티티
            
            pieceEntity.generateCollisionShapes(recursive: true)
            pieceEntity.scale = [0.3, 8.0, 0.3]
            pieceEntity.position = [0, 0.2, 0]
            
            destinationTile.addChild(pieceEntity)

            
            print("✅ \(piece.entity.name)을 \(tileName)에 처음으로 배치했습니다.")
        }
}
