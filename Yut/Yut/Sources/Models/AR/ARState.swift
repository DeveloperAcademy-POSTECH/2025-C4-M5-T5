import Combine
import Foundation

/// 원본 AR 렌더링과 시스템 준비 상태다. 게임 규칙의 원본은 GameState다.
@MainActor
final class ARState: ObservableObject {
    @Published var placementPhase: BoardPlacementPhase = .loading
    @Published var gamePhase: GamePhase = .arSessionLoading
    @Published var recognizedArea: Float = 0
    @Published var showFinalFrame = false
    @Published var isCoordinatorReady = false
    @Published var errorMessage: String?
    @Published var usesManualThrow = false
    @Published var isPreparingBoard = false
    @Published var yutResult: YutResult?
    let minRequiredArea: Float = 15
    let gameManager: GameManager
    weak var coordinator: ARCoordinator?

    init(gameManager: GameManager) { self.gameManager = gameManager }
}

enum BoardPlacementPhase: Equatable {
    case loading, scanning, placing, adjusting, confirmed, waitingForHost, relocalizing
}
