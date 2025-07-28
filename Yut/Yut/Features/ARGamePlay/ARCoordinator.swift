import ARKit
import RealityKit
import Combine

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
}
