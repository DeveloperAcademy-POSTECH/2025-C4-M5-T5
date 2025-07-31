import Combine
import RealityKit
import SwiftUI

// MARK: - AR 상태 관리 클래스

class ARState: ObservableObject {
    // 현재 앱 상태 (초기값: 평면 탐색)
    @Published var sessionUUID: UUID = UUID()
    @Published var gamePhase: GamePhase = .arSessionLoading

    // Coordinator와 통신할 명령 스트림
    let actionStream = PassthroughSubject<ARAction, Never>()

    // GameManager 싱글톤 인스턴스
    @ObservedObject var gameManager = GameManager.shared
    
    // 윷 생성 버튼
    @Published var showThrowButton: Bool = true

    // 바닥 인식 면적 관련
    @Published var recognizedArea: Float = 0.0
    let minRequiredArea: Float = 15.0

    // 말 선택 및 이동 후보 위치
    @Published var selectedPieces: [PieceModel]? = nil
    @Published var availableDestinations: [String] = []
    
    // 업기 선택을 위한 이동 정보 임시 저장
    @Published var pendingMove: (pieces: [PieceModel], destination: String)? = nil

    // 윷 결과 (도:1 ~ 모:5)
    @Published var yutResult: YutResult? = nil

    // Coordinator 참조 추가
    weak var coordinator: ARCoordinator?

    @Published var showFinalFrame: Bool = false
}

extension ARState {
    // 게임 상태를 다른 피어들과 동기화
    func syncGameState() {
        coordinator?.syncGameState()
    }
}
