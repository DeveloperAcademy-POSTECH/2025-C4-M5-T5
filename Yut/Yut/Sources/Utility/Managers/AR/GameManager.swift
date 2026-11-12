import Foundation
import RealityKit

/// 확정된 게임 상태를 원본 말 모델에 투영한다. 규칙과 권한은 GameSessionController가 소유한다.
@MainActor
final class GameManager {
    private(set) var players: [PlayerModel] = []
    private(set) var snapshot: GameState?

    var currentPlayer: PlayerModel? { players.first { $0.id == snapshot?.currentPlayer?.id } }
    var pieces: [PieceModel] { players.flatMap(\.pieces) }
    var yutResult: YutResult? { snapshot?.latestResult }
    var cellStates: [String: [PieceModel]] {
        Dictionary(grouping: pieces.filter { if case .onBoard = $0.gamePosition { return true }; return false }, by: \.position)
    }

    func apply(_ state: GameState, assets: AssetCacheManager, models: [PlayerModel]) throws {
        // 차례·연출 단계만 달라지면 말 배열과 모델 연결을 다시 만들지 않는다.
        if let snapshot, snapshot.id == state.id, snapshot.players == state.players,
           snapshot.pieces == state.pieces, snapshot.selectedPieceID == state.selectedPieceID,
           players.count == state.players.count,
           players.allSatisfy({ player in models.contains { $0 === player } }) {
            self.snapshot = state
            return
        }
        let oldPieces = Dictionary(uniqueKeysWithValues: pieces.map { ($0.id, $0) })
        let ids = Set(state.pieces.map(\.id))
        for piece in pieces where !ids.contains(piece.id) { piece.entity.removeFromParent() }
        players = state.players.compactMap { player in models.first { $0.id == player.id } }
        guard players.count == state.players.count else { throw PresentationError.missingPlayer }
        for player in players {
            player.pieces = try state.pieces.filter { $0.playerID == player.id }.map { value in
                let piece: PieceModel
                if let existing = oldPieces[value.id] { piece = existing }
                else {
                    guard let template = assets.cachedModel(named: player.pieceEntity) else { throw PresentationError.missingModel }
                    piece = PieceModel(id: value.id, owner: player, entity: template.clone(recursive: true))
                }
                piece.gamePosition = value.position
                piece.groupID = value.groupID
                piece.position = value.cell ?? "_6_6"
                if case .onBoard(let route, _) = value.position { piece.routeIndex = route }
                piece.isSelected = value.groupID == state.selectedPiece?.groupID && player.id == state.currentPlayer?.id
                return piece
            }
        }
        snapshot = state
    }

    func reset() {
        for player in players {
            player.pieces.forEach { $0.entity.removeFromParent() }
            player.pieces = []
        }
        players = []
        snapshot = nil
    }

    private enum PresentationError: LocalizedError {
        case missingPlayer, missingModel
        var errorDescription: String? { "말 모델을 준비하지 못했습니다. 다시 시도해주세요." }
    }
}
