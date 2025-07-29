import SwiftUI
import Combine
import RealityKit

// MARK: - AR 상태 관리 클래스

class ARState: ObservableObject {
    // 현재 앱 상태 (초기값: 평면 탐색)
    @Published var gamePhase: GamePhase = .searchingForSurface

    // Coordinator와 통신할 명령 스트림
    let actionStream = PassthroughSubject<ARAction, Never>()
    
    // GameManager 싱글톤 인스턴스
    @ObservedObject var gameManager = GameManager.shared

    // 바닥 인식 면적 관련
    @Published var recognizedArea: Float = 0.0
    let minRequiredArea: Float = 15.0

    // 말 선택 및 이동 후보 위치
    @Published var selectedPiece: PieceModel? = nil
    @Published var availableDestinations: [String] = []

    // 윷 결과 (도:1 ~ 모:5)
//    @Published var yutResult: Int = 1
    @Published var yutResult: YutResult? = nil


    // Coordinator 참조 추가
    weak var coordinator: ARCoordinator?

}

extension ARState {
    // 게임 상태를 다른 피어들과 동기화
    func syncGameState() {
        coordinator?.syncGameState()
    }

    
    @Published var showFinalFrame: Bool = false

}
