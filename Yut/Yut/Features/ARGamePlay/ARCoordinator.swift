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
    
    // MARK: - Game Flow Control

    // 윷 결과 업데이트 후 -> 움직일 말 선택
    func yutThrowCompleted(with result: YutResult) {
        
        guard let arState = self.arState else { return }
        
        // 1. GameManager에 윷 결과를 업데이트합니다.
        arState.gameManager.yutResult = result
        print("\(result)")
        // 2. 이전에 있던 하이라이트를 모두 제거합니다.
        self.pieceManager.clearAllHighlights()
        
        // 3. 다음 단계는 항상 '움직일 말 선택'이 됩니다.
        DispatchQueue.main.async {
            arState.gamePhase = .selectingPieceToMove
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
