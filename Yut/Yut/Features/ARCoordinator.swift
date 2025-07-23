//
//  ARCoordinator.swift
//  Yut
//
//  Created by yunsly on 7/17/25.
//
// ARView 이벤트를 처리, SwiftUI와 연결하는 총괄 Coordinator

import ARKit
import RealityKit
import SwiftUI
import simd
import Combine

// ARView의 이벤트의 처리하고 SwiftUI와 연결
class ARCoordinator: NSObject, ARSessionDelegate {
    
    // MARK: - Properties
    
    // Managers : 강제 언래핑 (nil 아님이 보장)
    var gestureHandler: GestureHandler!
    var contentManager: ARContentManager!
    var gameLogicManager: GameLogicManager!

    weak var arView: ARView? {
        didSet {
            gestureHandler.arView = arView
        }
    }
    
    // 환경 세팅 시 최소 요구 면적 (15㎡ - 일단은 1로 ... )
    let minRequiredArea: Float = 1
    
    // MARK: - Initializer
    override init() {
        super.init()
        
        self.contentManager = ARContentManager(coordinator: self)
        self.gameLogicManager = GameLogicManager()
        self.gestureHandler = GestureHandler(coordinator: self)
    }
    
    // MARK: - Combine 세팅
    var arState: ARState? {
        didSet {
            subscribeToActionStream()
        }
    }
    private var cancellables = Set<AnyCancellable>()
 
    // ARState 의 actionStream 구독 -> 명령 처리
    private func subscribeToActionStream() {
        guard let arState = arState else { return }
        
        arState.actionStream
            .sink { [weak self] action in       // 메모리 누수 방지
                switch action {
                case .fixBoardPosition:
                    self?.contentManager.fixBoardPosition()
                case .disablePlaneVisualization:
                    self?.contentManager.disablePlaneVisualization()
                case .showDestinationsForNewPiece:
                    self?.arState?.selectedPiece = nil
                    if let positions = self?.gameLogicManager.getPossibleDestinations(for: nil, yutResult: 0) {
                        self?.arState?.possibleDestinations = positions // 1. 논리적 상태(데이터)를 업데이트합니다.
                        self?.contentManager.highlightPositions(names: positions) // 2. 시각적 상태(화면)를 업데이트합니다.
                    }
                    DispatchQueue.main.async {
                        self?.arState?.currentState = .selectingDestination
                    }
                case .showDestinationsForExistingPiece:
                    guard let piece = self?.arState?.selectedPiece, let yutResult = self?.arState?.yutResult else { return }
                    if let positions = self?.gameLogicManager.getPossibleDestinations(for: piece, yutResult: yutResult) {
                        self?.arState?.possibleDestinations = positions // 1. 논리적 상태(데이터)를 업데이트합니다.
                        self?.contentManager.highlightPositions(names: positions) // 2. 시각적 상태(화면)를 업데이트합니다.
                    }
                    DispatchQueue.main.async {
                        self?.arState?.currentState = .selectingDestination
                    }
                case .startMonitoringMotion:
                    self?.contentManager.startMonitoringMotion()
                    DispatchQueue.main.async {
                        self?.arState?.currentState = .selectingPieceToMove
                    }
                }
            }
            .store(in: &cancellables)           // 구독 관리
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            // 1. 앵커카 평면 앵커라면 시각화 모델 생성
            if let planeAnchor = anchor as? ARPlaneAnchor {
                // 평면 추가 로직을 contentManager에게 위임
                contentManager.addPlane(for: planeAnchor)
            }
            // 2. 윷판 배치할 앵커라면 판 배치
            else if let anchorName = anchor.name, anchorName == "YutBoardAnchor" {
                // 윷판 배치 로직을 contentManager에게 위임
                contentManager.placeYutBoard(on: anchor)
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        var recognizedArea: Float = 0.0      // 인식된 면적의 총 합
        
        // 업데이트 된 앵커들의 시각적/물리적 메시 갱신
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
            // 평면 업데이트 로직을 contentManager에게 위임
            contentManager.updatePlane(for: planeAnchor)
            recognizedArea += planeAnchor.meshArea
    
        }
        
        // print("인식된 평면의 실제 면적: \(recognizedArea)㎡")
        
        // 전체 면적이 최소 요구 면적을 넘으면 상태 변경
        if arState?.currentState == .searchingForSurface && recognizedArea >= minRequiredArea {
            DispatchQueue.main.async {
                self.arState?.currentState = .completedSearching
            }
        }
    }

    // MARK: - Other Logic
}
