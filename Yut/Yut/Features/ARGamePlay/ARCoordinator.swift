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
                arState.coordinator = self  // coordinator 참조 설정
                actionStreamHandler.subscribe(to: arState)
            }
        }
    }
    
    // MARK: - MPC 연결
    private let mpcManager = MPCManager.shared
    
    // MARK: - 서브 매니저
    
    var gestureHandler: GestureHandler!
    var boardManager: BoardManager!
    var planeManager: PlaneManager!
    var pieceManager: PieceManager!
    var yutManager: YutManager!
    var assetCacheManager: AssetCacheManager!
    var actionStreamHandler: ActionStreamHandler!
    
    // MARK: - 초기화
    
    override init() {
        super.init()
        self.boardManager = BoardManager(coordinator: self)
        self.planeManager = PlaneManager(coordinator: self)
        self.pieceManager = PieceManager(coordinator: self)
        self.yutManager = YutManager(coordinator: self)
        self.assetCacheManager = AssetCacheManager()
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
                
                // Host가 말판을 배치했을 때 다른 피어들과 공유
                if mpcManager.isHost {
                    print("🎯 Host: 말판 앵커 추가됨 - Guest들과 공유 중...")
                    // 앵커가 자동으로 다른 피어들과 공유됨
                }
            }
        }
    }
    
    func session(_ session: ARSession, didReceive anchors: [ARAnchor]) {
        for anchor in anchors {
            if let name = anchor.name, name == "YutBoardAnchor" {
                print("📥 Guest: Host로부터 말판 앵커 수신")
                // Guest는 Host가 보낸 앵커를 받아서 같은 위치에 배치
                boardManager.placeYutBoard(on: anchor)
            }
        }
    }
    
    // 협업 데이터 수신 및 전송
    func session(_ session: ARSession, didReceive collaborationData: Data) {
        // MPC를 통해 협업 데이터 전송
        if let mpcSession = mpcManager.session {
            try? mpcSession.send(collaborationData, toPeers: mpcSession.connectedPeers, with: .reliable)
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
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                planeManager.removePlane(for: planeAnchor)
            }
        }
    }
    
    // MARK: - Game Flow Control
    
    // '새 게임 준비' 액션을 처리하는 함수
    func setupNewGame() {
        Task {
            // Main 스레드
            // GameManager 설정, 게임 상태 변경
            @MainActor in
            
            // PlayerModel 로드 (PeerID 임시값)
//            let player1 = PlayerModel(name: "노랑", sequence: 1, peerID: MCPeerID(displayName: "Player1"))
//            let player2 = PlayerModel(name: "초록", sequence: 2, peerID: MCPeerID(displayName: "Player2"))
            let players = MPCManager.shared.players
            
            guard let arState = self.arState else { return }
            
            // GameManager에 실제 플레이어 정보로 새 게임을 설정
//            arState.gameManager.startGame(with: [player1, player2])
            arState.gameManager.startGame(with: players)
            
            // PieceManager 윷판 앵커를 알 수 있도록 연결
            self.pieceManager.boardAnchor = self.boardManager.yutBoardAnchor
            
            // 준비 끝, 상태 전환
            arState.gamePhase = .readyToThrow
            
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
        
//        print("새말 놓을 때 \(gameManager.currentPlayer.pieces[0])")
        let piece = gameManager.currentPlayer.pieces[0]
        print("새말 놓을 때 id: \(piece.id), isOnBoard: \(piece.isSelected), position: \(piece.position)")
        
        let destinations = gameManager.routeOptions(for: newPiece, yutResult: yutResult, currentRouteIndex: newPiece.routeIndex)
        
        // 목적지 타일 하이라이트
        if !destinations.isEmpty {
            let destinationNames = destinations.map { $0.destinationID }
            self.pieceManager.highlightTiles(named: destinationNames)
            
            arState.selectedPiece = newPiece
            arState.availableDestinations = destinationNames
            DispatchQueue.main.async {
                arState.gamePhase = .selectingDestination
            }
        }
    }
    
    // 윷 결과 업데이트 후 -> 움직일 말 선택
    func yutThrowCompleted(with result: YutResult) {
        
        guard let arState = self.arState else { return }
        
        // 윷 결과 업데이트 (UI 반영, 매니저에게 전달)
        arState.yutResult = result
        arState.gameManager.yutResult = result
        print("윷 결과\(result)")
        
        self.pieceManager.clearAllHighlights()
        
        DispatchQueue.main.async {
            arState.gamePhase = .showingYutResult
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // 1. 던져진 윷 제거
                if let yutManager = arState.coordinator?.yutManager {
                    for yutModel in yutManager.thrownYuts {
                        yutModel.entity.parent?.removeFromParent()
                    }
                    yutManager.thrownYuts.removeAll()
                }
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
    
    // MARK: - MPC 협업 기능
    
    // Host가 말판을 배치할 때 호출
    func placeBoardForCollaboration(at position: SIMD3<Float>) {
        guard mpcManager.isHost else { return }
        
        // 말판 앵커 생성 및 추가
        let anchor = ARAnchor(name: "YutBoardAnchor", transform: matrix_identity_float4x4)
        arView?.session.add(anchor: anchor)
        
        print("🎯 Host: 말판 배치 완료 - Guest들과 공유 중...")
    }
    
    // 게임 상태를 다른 피어들과 동기화
    func syncGameState() {
        guard let arState = self.arState else { return }
        
        let gameState = GameStateData(
            currentPlayer: arState.gameManager.currentPlayer.name,
            gamePhase: arState.gamePhase,
            yutResult: arState.gameManager.yutResult
        )
        
        if let data = try? JSONEncoder().encode(gameState) {
            try? mpcManager.session.send(data, toPeers: mpcManager.session.connectedPeers, with: .reliable)
        }
    }
}

// 게임 상태 데이터 구조
struct GameStateData: Codable {
    let currentPlayer: String
    let gamePhaseString: String
    let yutResultInt: Int?
    
    init(currentPlayer: String, gamePhase: GamePhase, yutResult: YutResult?) {
        self.currentPlayer = currentPlayer
        self.gamePhaseString = String(describing: gamePhase)
        self.yutResultInt = yutResult?.rawValue
    }
}
