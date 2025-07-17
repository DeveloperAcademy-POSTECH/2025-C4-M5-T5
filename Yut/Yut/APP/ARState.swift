//
//  ARState.swift
//  Yut
//
//  Created by yunsly on 7/17/25.
//

import SwiftUI
import Combine

// Coordinator 에게 전달할 명령 정의
enum ARAction {
    case fixBoardPosition
    case disablePlaneVisualization
    case createYuts
}

// 앱의 현재 단계 정의
enum AppState {
    case searchingForSurface    // 1. 평면을 찾고 있는 단계
    case completedSearching     // 2. 최소 넓이의 평면 인식이 완료된 단계
    case placeBoard             // 3. 탭으로 윷판을 배치하는 단계
    case adjustingBoard         // 4. 윷판의 위치와 크기를 조절하는 단계
    case boardConfirmed         // 5. 윷판 확정, 게임 시작 준비
    case readyToThrow           // 6. 윷을 던질 준비
}

// 앱의 상태 관리, 뷰와 공유
class ARState: ObservableObject {
    @Published var currentState: AppState = .searchingForSurface
    
    // 명령 전달 통로 (Coordinator 구독 -> 처리)
    let actionStream = PassthroughSubject<ARAction, Never>()
}

