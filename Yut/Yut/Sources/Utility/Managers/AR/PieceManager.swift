import Foundation
import RealityKit

/// 원본 말 크기·이동 연출을 사용하되 업힌 그룹은 확정된 groupID로 배치한다.
@MainActor
final class PieceManager {
    var boardAnchor: AnchorEntity {
        didSet { prepareTileRendering() }
    }
    let gameManager: GameManager
    static let pieceScale: SIMD3<Float> = [0.3, 10, 0.3]
    private var tileModels: [String: ModelComponent] = [:]
    private var hiddenTileNames: Set<String> = []
    private var highlightedTiles: [Entity] = []
    private var moveTasks: [ObjectIdentifier: Task<Void, Never>] = [:]
    private var layoutTask: Task<Void, Never>?
    private var generation = UUID()

    init(boardAnchor: AnchorEntity, gameManager: GameManager) {
        self.boardAnchor = boardAnchor
        self.gameManager = gameManager
        prepareTileRendering()
    }

    func render(previous: GameState?, current: GameState, force: Bool = false) {
        guard force || previous?.id != current.id || previous?.pieces != current.pieces else { return }
        stopAnimations()
        let expected = generation
        var hasMovingPiece = false
        for piece in gameManager.pieces {
            guard case .onBoard = piece.gamePosition else { piece.entity.removeFromParent(); continue }
            if piece.entity.parent == nil { placePieceOnBoard(piece: piece, on: piece.position) }
            else if !force, previous?.pieces.first(where: { $0.id == piece.id })?.cell != piece.position {
                movePiece(piece: piece.entity, to: piece.position)
                hasMovingPiece = true
            }
        }
        layoutTask = Task { [weak self] in
            do { try await Task.sleep(for: hasMovingPiece ? .milliseconds(510) : .milliseconds(350)) } catch { return }
            guard let self, generation == expected else { return }
            for cell in gameManager.cellStates.keys { arrangePiecesOnTile(cell) }
        }
    }

    func placePieceOnBoard(piece: PieceModel, on name: String) {
        guard let tile = boardAnchor.findEntity(named: name) else { return }
        piece.entity.removeFromParent()
        piece.entity.name = piece.id.uuidString
        piece.entity.generateCollisionShapes(recursive: true)
        piece.entity.scale = Self.pieceScale
        piece.entity.position = [0, 0.1, 0]
        tile.addChild(piece.entity)
    }

    func movePiece(piece: Entity, to name: String) {
        guard let tile = boardAnchor.findEntity(named: name) else { return }
        var position = tile.position(relativeTo: nil)
        position.y += 0.02
        var transform = Transform(matrix: piece.transformMatrix(relativeTo: nil))
        transform.translation = position
        piece.move(to: transform, relativeTo: nil, duration: 0.5, timingFunction: .easeInOut)
        let expected = generation
        let key = ObjectIdentifier(piece)
        moveTasks[key]?.cancel()
        moveTasks[key] = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
            guard let self, generation == expected else { return }
            piece.setParent(tile)
            piece.setPosition([0, 0.02, 0], relativeTo: tile)
            moveTasks.removeValue(forKey: key)
        }
    }

    private func arrangePiecesOnTile(_ name: String) {
        guard let tile = boardAnchor.findEntity(named: name), let pieces = gameManager.cellStates[name] else { return }
        let groups = Array(Set(pieces.map(\.groupID))).sorted { $0.uuidString < $1.uuidString }
        for (groupIndex, group) in groups.enumerated() {
            let stack = pieces.filter { $0.groupID == group }.sorted { $0.id.uuidString < $1.id.uuidString }
            let x = Float(groupIndex) * 0.2 - Float(groups.count - 1) * 0.1
            for (height, piece) in stack.enumerated() {
                piece.entity.setParent(tile, preservingWorldTransform: true)
                let transform = Transform(scale: Self.pieceScale, rotation: piece.entity.orientation,
                                          translation: [x, Float(height) * 0.7, 0])
                piece.entity.move(to: transform, relativeTo: tile, duration: 0.25)
            }
        }
    }

    func highlightTiles(named names: [String]) {
        clearAllHighlights()
        for name in names {
            guard let tile = boardAnchor.findEntity(named: name),
                  var model = tileModels[name] else { continue }
            var highlight = UnlitMaterial()
            highlight.color = .init(tint: .yellow.withAlphaComponent(0.8))
            model.materials = [highlight]
            tile.components.set(model)
            highlightedTiles.append(tile)
        }
    }

    func clearAllHighlights() {
        for tile in highlightedTiles {
            if hiddenTileNames.contains(tile.name) { tile.components.remove(ModelComponent.self) }
            else if let model = tileModels[tile.name] { tile.components.set(model) }
        }
        highlightedTiles = []
    }

    /// 투명한 선택용 칸은 충돌·자식·좌표를 남기고, 강조할 때만 원본 메시를 렌더링한다.
    /// 말판 고정 시 앵커가 복제되므로 모델은 엔티티 참조 대신 칸 이름으로 보관한다.
    private func prepareTileRendering() {
        clearAllHighlights()
        let names = Set(GameBoard.routes.flatMap { $0 }).union(["end"])
        for name in names {
            guard let tile = boardAnchor.findEntity(named: name) else { continue }
            if tileModels[name] == nil { tileModels[name] = tile.components[ModelComponent.self] }
            guard let model = tileModels[name], !model.materials.isEmpty else { continue }
            let isTransparent = model.materials.allSatisfy {
                guard let material = $0 as? PhysicallyBasedMaterial else { return false }
                return material.baseColor.tint.cgColor.alpha == 0
            }
            if isTransparent {
                hiddenTileNames.insert(name)
                tile.components.remove(ModelComponent.self)
            }
        }
    }

    func stop() {
        stopAnimations()
        clearAllHighlights()
    }

    private func stopAnimations() {
        generation = UUID()
        layoutTask?.cancel()
        moveTasks.values.forEach { $0.cancel() }
        moveTasks = [:]
    }
}
