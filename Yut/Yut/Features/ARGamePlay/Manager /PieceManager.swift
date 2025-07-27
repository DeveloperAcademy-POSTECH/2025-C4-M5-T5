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
    
    private var originalMaterials: [String: RealityFoundation.Material] = [:]
    
    
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
    
    func highlightPositions(_ names: [String]) {
        guard let boardEntity = boardAnchor?.children.first else {
            print("❌ 윷판 엔티티 없음")
            return
        }
        
        clearHighlights()
        
        for name in names {
            guard let tile = boardEntity.findEntity(named: name) as? ModelEntity else {
                print("❌ 타일 \(name) 없음")
                continue
            }
            
            if let material = tile.model?.materials.first {
                originalMaterials[name] = material
            }
            
            var highlightMaterial = UnlitMaterial()
            highlightMaterial.color = .init(tint: .yellow.withAlphaComponent(0.8))
            
            if var model = tile.model {
                model.materials = [highlightMaterial]
                tile.model = model
            }
        }
    }
    
    func clearHighlights() {
        guard let boardEntity = boardAnchor?.children.first else { return }
        
        for (name, original) in originalMaterials {
            if let tile = boardEntity.findEntity(named: name) as? ModelEntity,
               var model = tile.model {
                model.materials = [original]
                tile.model = model
            }
        }
        
        originalMaterials.removeAll()
    }
}
