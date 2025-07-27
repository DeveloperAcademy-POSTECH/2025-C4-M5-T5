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
    
    /// 외부에서 호출되는 공용 처리 함수
    private func handle(_ action: ARAction) {
        switch action {
        case .fixBoardPosition:
            coordinator.boardManager.fixBoardPosition()
            
        case .disablePlaneVisualization:
            coordinator.planeManager.disablePlaneVisualization()
            
        case .setupNewGame:
            Task {
                // 1명 호스트, 3명 게스트 (총 4명) 더미 플레이어 생성
                let playerSpecs: [(String, Int, Bool)] = [
                    ("호스트", 0, true),
                    ("게스트1", 1, false),
                    ("게스트2", 2, false),
                    ("게스트3", 3, false)
                ]
                let players: [PlayerModel] = await withTaskGroup(of: PlayerModel.self) { group in
                    for (name, seq, isHost) in playerSpecs {
                        // peerID의 displayName을 이름과 동일하게 둔다
                        let peerID = MCPeerID(displayName: name)
                        group.addTask {
                            await PlayerModel.load(
                                name: name,
                                sequence: seq,
                                peerID: peerID,
                                isHost: isHost
                            )
                        }
                    }
                    var result: [PlayerModel] = []
                    for await player in group {
                        result.append(player)
                    }
                    // sequence 순으로 정렬
                    return result.sorted { $0.sequence < $1.sequence }
                }
                coordinator.arState?.gameManager.startGame(with: players)
                coordinator.pieceManager.boardAnchor = coordinator.boardManager.yutBoardAnchor
                
                await MainActor.run {
                    coordinator.arState?.gamePhase = .readyToThrow
                }
            }
//
//        case .showDestinationsForNewPiece:
//            handleShowDestinationsForNewPiece()
//
//        case .showDestinationsForExistingPiece:
//            handleShowDestinationsForExistingPiece()
            
        case .startMonitoringMotion:
            coordinator.yutManager.startMonitoringMotion()
            Task { @MainActor in
                coordinator.arState?.gamePhase = .selectingPieceToMove
            }
        }
    }
    
//    /// 새 말을 위한 목적지 계산 및 하이라이트 처리
//    private func handleShowDestinationsForNewPiece() {
//        coordinator.arState?.selectedPiece = nil
//
//        let positions = coordinator.gameLogicManager.getPossibleDestinations(
//            for: nil,
//            yutResult: 0
//        )
//
//        coordinator.arState?.possibleDestinations = positions
//        coordinator.pieceManager.highlightPositions(positions)
//
//        Task { @MainActor in
//            coordinator.arState?.gamePhase = .selectingDestination
//        }
//    }
//
//    /// 기존 말을 위한 목적지 계산 및 하이라이트 처리
//    private func handleShowDestinationsForExistingPiece() {
//        guard let piece = coordinator.arState?.selectedPiece,
//              let yutResult = coordinator.arState?.yutResult else { return }
//
//        let positions = coordinator.gameLogicManager.getPossibleDestinations(
//            for: piece,
//            yutResult: yutResult
//        )
//
//        coordinator.arState?.possibleDestinations = positions
//        coordinator.pieceManager.highlightPositions(positions)
//
//        Task { @MainActor in
//            coordinator.arState?.gamePhase = .selectingDestination
//        }
//    }
}
