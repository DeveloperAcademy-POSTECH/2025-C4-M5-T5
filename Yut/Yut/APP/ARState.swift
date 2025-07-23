//
//  ARState.swift
//  Yut
//
//  Created by yunsly on 7/17/25.
//

import SwiftUI
import Combine
import RealityKit

// Coordinator 에게 전달할 명령 정의
enum ARAction {
    case fixBoardPosition
    case disablePlaneVisualization
    // case showPossibleDestinations
    case showDestinationsForNewPiece
    case showDestinationsForExistingPiece
    case startMonitoringMotion
}

// 앱의 현재 단계 정의
enum AppState {
    // -- 초기 설정 단계 --
    case searchingForSurface    // 1. 평면을 찾고 있는 단계
    case completedSearching     // 2. 최소 넓이의 평면 인식이 완료된 단계
    case placeBoard             // 3. 탭으로 윷판을 배치하는 단계
    case adjustingBoard         // 4. 윷판의 위치와 크기를 조절하는 단계
    case boardConfirmed         // 5. 윷판 확정, 게임 시작 준비
    
    // -- 실제 게임 플레이 루프 단계 --
    case readyToThrow           // 1. 윷을 던질 준비
    case selectingPieceToMove   // 2. 보드 위 움직일 말 선택
    case selectingDestination   // 3. 이동할 위치 선택 (경로 하이라이트)
//    case pieceMoved             // 4. 말 이동 후 턴 종료 or 다음 행동 결정
    
}

// 앱의 상태 관리, 뷰와 공유
class ARState: ObservableObject {
    @Published var currentState: AppState = .searchingForSurface
    
    // 명령 전달 통로 (Coordinator 구독 -> 처리)
    let actionStream = PassthroughSubject<ARAction, Never>()
    
    @Published var selectedPiece: Entity? = nil
    @Published var possibleDestinations: [String] = []
    
    @Published var yutResult: Int = 1
}

