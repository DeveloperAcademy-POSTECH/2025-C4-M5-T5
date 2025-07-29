import ARKit
import RealityKit
import Combine
import MultipeerConnectivity

/// ARView의 이벤트를 처리하고 SwiftUI 상태와 연결해주는 총괄 Coordinator
class ARCoordinator: NSObject, ARSessionDelegate {
    
    // MARK: - 외부 연결 (의존 객체)
    
    weak var arView: ARView? {
        didSet {
            gestureHandler.arView = arView
        }
    }
    
    var arState: ARState? {
        didSet {
            if let arState {
                actionStreamHandler.subscribe(to: arState)
            }
        }
    }
    
    // MARK: - 서브 매니저
    
    var gestureHandler: GestureHandler!
    var boardManager: BoardManager!
    var planeManager: PlaneManager!
    var pieceManager: PieceManager!
    var yutManager: YutManager!
    var actionStreamHandler: ActionStreamHandler!
    
    // MARK: - 초기화
    
    override init() {
        super.init()
        self.boardManager = BoardManager(coordinator: self)
        self.planeManager = PlaneManager(coordinator: self)
        self.pieceManager = PieceManager()
        self.yutManager = YutManager(coordinator: self)
        self.gestureHandler = GestureHandler(coordinator: self)
        self.actionStreamHandler = ActionStreamHandler(coordinator: self)
    }
    
    // MARK: - ARSessionDelegate (앵커 업데이트 처리)
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                planeManager.addPlane(for: planeAnchor)
            } else if let name = anchor.name, name == "YutBoardAnchor" {
                boardManager.placeYutBoard(on: anchor)
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        var recognizedArea: Float = 0.0
        
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
            planeManager.updatePlane(for: planeAnchor)
            recognizedArea += planeAnchor.meshArea
        }
        
        let roundedArea = round(recognizedArea * 10) / 10.0
        
        Task { @MainActor in
            guard let arState = self.arState else { return }
            
            // 🔥 값이 감소한 경우 무시
            if roundedArea < arState.recognizedArea { return }
            
            if arState.recognizedArea != roundedArea {
                arState.recognizedArea = roundedArea
            }
        }
    }
    
    // MARK: - Game Flow Control
    
    // '새 게임 준비' 액션을 처리하는 함수
    func setupNewGame() {
        Task {
            // Main 스레드
            // GameManager 설정, 게임 상태 변경
            
            await MainActor.run {
                // PlayerModel 로드 (PeerID 임시값)
                let player1 = PlayerModel(name: "노랑", sequence: 1, peerID: MCPeerID(displayName: "Player1"))
                let player2 = PlayerModel(name: "초록", sequence: 2, peerID: MCPeerID(displayName: "Player2"))
                
                guard let arState = self.arState else { return }
                
                // GameManager에 실제 플레이어 정보로 새 게임을 설정
                arState.gameManager.startGame(with: [player1, player2])
                
                // PieceManager 윷판 앵커를 알 수 있도록 연결
                self.pieceManager.boardAnchor = self.boardManager.yutBoardAnchor
                
                // 준비 끝, 상태 전환
                arState.gamePhase = .readyToThrow
            }
        }
    }
    
    // 새 말 놓을 때
    func showDestinationsForNewPiece() {
        guard let arState = self.arState else { return }
        let gameManager = arState.gameManager
        
        // 시작점에 있는 말과, 윷 결과 게임매니저로부터 가져오기
        guard let newPiece = gameManager.currentPlayer.pieces.first(where: { $0.position == "_6_6" }),
              let yutResult = gameManager.yutResult
        else { return }
        
        let destinations = gameManager.routeOptions(for: newPiece, yutResult: yutResult, currentRouteIndex: newPiece.routeIndex)
        
        // 목적지 타일 하이라이트
        if !destinations.isEmpty {
            let destinationNames = destinations.map { $0.destinationID }
            self.pieceManager.highlightTiles(named: destinationNames)
            
            arState.selectedPiece = newPiece
            arState.availableDestinations = destinationNames
            arState.gamePhase = .selectingDestination
        }
    }
    
    // 윷 결과 업데이트 후 -> 움직일 말 선택
    func yutThrowCompleted(with result: YutResult) {
        
        guard let arState = self.arState else { return }
        
        // 1. GameManager에 윷 결과를 업데이트합니다.
        arState.gameManager.yutResult = result
        print("\(result)")
        // 2. 이전에 있던 하이라이트를 모두 제거합니다.
        self.pieceManager.clearAllHighlights()
        
        // 3. 다음 단계는 '윷 던지기 결과 표시' 3초 후 '움직일 말 선택'이 됩니다.
        DispatchQueue.main.async {
            arState.gamePhase = .showingYutResult
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                arState.gamePhase = .selectingPieceToMove
            }
        }
    }
    
    // ✨ 턴을 종료하고 다음 플레이어를 준비시키는 헬퍼 함수
    func endTurn() {
        guard let arState = self.arState else { return }
        let gameManager = arState.gameManager
        
        // 윷이나 모가 아니라면 다음 플레이어로 턴을 넘깁니다.
        if gameManager.yutResult?.isExtraTurn == false {
            gameManager.nextTurn()
            print("턴 종료! 다음 플레이어: \(gameManager.currentPlayer.name)")
        } else {
            print("🎁 윷이나 모! 한 번 더 던지세요.")
        }
        
        // 다시 윷을 던질 준비 상태로 돌아갑니다.
        arState.gamePhase = .readyToThrow
    }
}
