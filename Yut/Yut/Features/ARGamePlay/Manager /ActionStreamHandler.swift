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
                // 1. 실제 플레이어와 말 모델(Entity)들을 비동기로 로드합니다.
                //    (PlayerModel에 만들어두신 load 함수를 활용)
                //    peerID는 멀티플레이 구현 전이므로 임시값을 사용합니다.
                
                // Main 스레드에서 GameManager를 설정하고 게임 상태를 변경합니다.
                await MainActor.run {
                    let player1 = PlayerModel(name: "노랑", sequence: 1, peerID: MCPeerID(displayName: "Player1"))
                    let player2 = PlayerModel(name: "초록", sequence: 2, peerID: MCPeerID(displayName: "Player2"))
                    
                    guard let arState = coordinator.arState,
                          let boardManager = coordinator.boardManager,
                          let pieceManager = coordinator.pieceManager
                    else { return }
                    
                    // 2. GameManager에 실제 플레이어 정보로 새 게임을 설정합니다.
                    arState.gameManager.startGame(with: [player1, player2])
                    
                    // 3. PieceManager가 윷판 앵커를 알 수 있도록 연결합니다.
                    pieceManager.boardAnchor = boardManager.yutBoardAnchor
                    
                    // 4. 모든 준비가 끝났으니, 윷을 던질 준비 상태로 전환합니다.
                    arState.gamePhase = .readyToThrow
                }
            }
            
        case .showDestinationsForNewPiece:
            guard let arState = coordinator.arState else { return }
            let gameManager = arState.gameManager
            
            // 1. 현재 플레이어의 말 중 판 밖에 있는 첫 번째 말을 찾습니다.
            guard let newPiece = gameManager.currentPlayer.pieces.first(where: { $0.position == "_6_6" }),
                  let yutResult = gameManager.yutResult
            else {
                print("말이없어잉")
                return
            }
            
            // 2. 그 말의 목적지를 계산합니다.
            let destinations = gameManager.routeOptions(for: newPiece, yutResult: yutResult, currentRouteIndex: newPiece.routeIndex)
            
            if !destinations.isEmpty {
                // 3. 목적지 타일들을 하이라이트합니다.
                let destinationNames = destinations.map { $0.destinationID }
                coordinator.pieceManager.highlightTiles(named: destinationNames)
                
                // 4. '새 말'을 선택된 것으로 상태에 저장하고, '목적지 선택' 단계로 전환합니다.
                arState.selectedPiece = newPiece
                arState.availableDestinations = destinationNames
                arState.gamePhase = .selectingDestination
            }
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
