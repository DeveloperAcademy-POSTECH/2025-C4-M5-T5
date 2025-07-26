//
//  ARCoordinator.swift
//  Yut
//
//  Created by yunsly on 7/17/25.
//

import ARKit
import RealityKit
import SwiftUI
import simd
import Combine

/// ARView의 이벤트를 처리하고 SwiftUI 상태와 연결해주는 총괄 Coordinator
class ARCoordinator: NSObject, ARSessionDelegate {
    
    // MARK: - Managers (필수 하위 관리자들)
    
    // 사용자 제스처 처리
    var gestureHandler: GestureHandler!
    
    // 콘텐츠 배치 및 물리적 처리 담당
    var contentManager: ARContentManager!
    
    // 게임 로직 계산 담당
    var gameLogicManager: GameLogicManager!
    
    // MARK: - ARView 연결 (순환 참조 방지 위해 weak 사용)
    
    weak var arView: ARView? {
        didSet {
            // arView가 설정될 때 제스처 핸들러에도 전달
            gestureHandler.arView = arView
        }
    }
    
    // MARK: - 초기화
    
    override init() {
        super.init()
        
        // 하위 모듈 생성 및 연결 (자기 자신을 넘김)
        self.contentManager = ARContentManager(coordinator: self)
        self.gameLogicManager = GameLogicManager()
        self.gestureHandler = GestureHandler(coordinator: self)
    }
    
    // MARK: - 상태 공유 모델
    
    /// SwiftUI 측 상태 모델
    var arState: ARState? {
        didSet {
            subscribeToActionStream()
        }
    }
    
    // MARK: - Combine
    
    /// Combine 구독을 담아두는 Set (retain 목적으로 필요)
    private var cancellables = Set<AnyCancellable>()
    
    /// arState의 actionStream을 구독하고, 명령을 분기 처리
    private func subscribeToActionStream() {
        guard let arState = arState else { return }
        
        arState.actionStream
            .sink { [weak self] action in
                guard let self = self else { return }
                
                switch action {
                case .fixBoardPosition:
                    self.contentManager.fixBoardPosition()
                    
                case .disablePlaneVisualization:
                    self.contentManager.disablePlaneVisualization()
                    
                case .showDestinationsForNewPiece:
                    self.arState?.selectedPiece = nil
                    let positions = self.gameLogicManager.getPossibleDestinations(for: nil, yutResult: 0)
                    self.arState?.possibleDestinations = positions
                    self.contentManager.highlightPositions(names: positions)
                    DispatchQueue.main.async {
                        self.arState?.currentState = .selectingDestination
                    }
                    
                case .showDestinationsForExistingPiece:
                    guard let piece = self.arState?.selectedPiece,
                          let yutResult = self.arState?.yutResult else { return }
                    let positions = self.gameLogicManager.getPossibleDestinations(for: piece, yutResult: yutResult)
                    self.arState?.possibleDestinations = positions
                    self.contentManager.highlightPositions(names: positions)
                    DispatchQueue.main.async {
                        self.arState?.currentState = .selectingDestination
                    }
                    
                case .startMonitoringMotion:
                    self.contentManager.startMonitoringMotion()
                    DispatchQueue.main.async {
                        self.arState?.currentState = .selectingPieceToMove
                    }
                }
            }
            .store(in: &cancellables) // 메모리 누수 방지
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                contentManager.addPlane(for: planeAnchor)
            } else if let name = anchor.name, name == "YutBoardAnchor" {
                contentManager.placeYutBoard(on: anchor)
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        var recognizedArea: Float = 0.0
        
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
            contentManager.updatePlane(for: planeAnchor)
            recognizedArea += planeAnchor.meshArea
        }
        
        Task { @MainActor in
            self.arState?.recognizedArea = recognizedArea
            guard let arState = self.arState else { return }
            
            if arState.currentState == .searchingForSurface &&
                recognizedArea >= arState.minRequiredArea {
                arState.currentState = .completedSearching
            }
        }
    }
}
