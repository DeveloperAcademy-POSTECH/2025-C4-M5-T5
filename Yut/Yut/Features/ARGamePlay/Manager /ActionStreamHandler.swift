/// ARCoordinator로부터 명령을 위임받아 처리하는 액션 핸들러
import Combine

final class ActionStreamHandler {
    unowned let coordinator: ARCoordinator
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: ARCoordinator) {
        self.coordinator = coordinator
    }
    
    func subscribe(to arState: ARState) {
            arState.actionStream
                .sink { [weak self] action in
                    self?.handle(action)
                }
                .store(in: &cancellables)
        }

    /// 외부에서 호출되는 공용 처리 함수
    private func handle(_ action: ARAction) {
        switch action {
        case .fixBoardPosition:
            coordinator.boardManager.fixBoardPosition()

        case .disablePlaneVisualization:
            coordinator.planeManager.disablePlaneVisualization()

        case .showDestinationsForNewPiece:
            handleShowDestinationsForNewPiece()

        case .showDestinationsForExistingPiece:
            handleShowDestinationsForExistingPiece()

        case .preloadYutModels:
            coordinator.yutManager.preloadYutModels()
        
        case .startMonitoringMotion:
            coordinator.yutManager.startMonitoringMotion()
            Task { @MainActor in
                coordinator.arState?.gamePhase = .selectingPieceToMove
            }
        }
    }

    /// 새 말을 위한 목적지 계산 및 하이라이트 처리
    private func handleShowDestinationsForNewPiece() {
        coordinator.arState?.selectedPiece = nil

        let positions = coordinator.gameLogicManager.getPossibleDestinations(
            for: nil,
            yutResult: 0
        )

        coordinator.arState?.possibleDestinations = positions
        coordinator.pieceManager.highlightPositions(positions)

        Task { @MainActor in
            coordinator.arState?.gamePhase = .selectingDestination
        }
    }

    /// 기존 말을 위한 목적지 계산 및 하이라이트 처리
    private func handleShowDestinationsForExistingPiece() {
        guard let piece = coordinator.arState?.selectedPiece,
              let yutResult = coordinator.arState?.yutResult else { return }

        let positions = coordinator.gameLogicManager.getPossibleDestinations(
            for: piece,
            yutResult: yutResult
        )

        coordinator.arState?.possibleDestinations = positions
        coordinator.pieceManager.highlightPositions(positions)

        Task { @MainActor in
            coordinator.arState?.gamePhase = .selectingDestination
        }
    }
}
