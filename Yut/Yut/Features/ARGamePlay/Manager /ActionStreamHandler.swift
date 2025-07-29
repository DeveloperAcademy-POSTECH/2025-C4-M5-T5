/// ARCoordinator로부터 명령을 위임받아 처리하는 액션 핸들러
import Combine
import MultipeerConnectivity

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
    
    // 외부에서 호출되는 공용 처리 함수
    private func handle(_ action: ARAction) {
        switch action {
        case .fixBoardPosition:
            coordinator.boardManager.fixBoardPosition()
            
        case .disablePlaneVisualization:
            coordinator.planeManager.disablePlaneVisualization()
            
        case .setupNewGame:
            coordinator.setupNewGame()
        
        case .showDestinationsForNewPiece:
            coordinator.showDestinationsForNewPiece()

        // setupNewGame에서 실행해도 괜찮을 듯
        case .preloadYutModels:
            coordinator.yutManager.preloadYutModels()
        
        case .startMonitoringMotion:
            coordinator.yutManager.startMonitoringMotion()
            
        case .setYutResultForTesting(let result):
            coordinator.yutThrowCompleted(with: result)
        }
        
    }
}
