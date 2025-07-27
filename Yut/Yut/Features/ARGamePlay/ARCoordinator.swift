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
    var gameLogicManager: GameLogicManager!
    var actionStreamHandler: ActionStreamHandler!
    
    // MARK: - 초기화

    override init() {
        super.init()
        self.boardManager = BoardManager(coordinator: self)
        self.planeManager = PlaneManager(coordinator: self)
        self.pieceManager = PieceManager()
        self.yutManager = YutManager(coordinator: self)
        self.gameLogicManager = GameLogicManager()
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
}
