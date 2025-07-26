import SwiftUI
import Combine
import RealityKit

// MARK: - Coordinator에게 전달할 명령 정의
enum ARAction {
    case fixBoardPosition
    case disablePlaneVisualization
    case showDestinationsForNewPiece
    case showDestinationsForExistingPiece
    case startMonitoringMotion
}

// MARK: - 게임 상태(단계) 정의
enum GamePhase {
    // 초기 설정 단계
    case searchingForSurface        // 1. 평면을 찾는 중
    case completedSearching         // 2. 충분한 평면 인식 완료
    case placeBoard                 // 3. 탭으로 윷판 배치
    case adjustingBoard             // 4. 위치 및 크기 조절
    case boardConfirmed             // 5. 윷판 확정, 시작 대기
    
    // 게임 진행 단계
    case readyToThrow               // 6. 윷 던지기 준비
    case selectingPieceToMove       // 7. 말을 선택
    case selectingDestination       // 8. 이동할 위치 선택
    // case pieceMoved              // (예정) 말 이동 완료
}

// MARK: - AR 상태 관리 클래스
class ARState: ObservableObject {
    // 현재 앱 상태 (초기값: 평면 탐색)
    @Published var currentState: GamePhase = .searchingForSurface

    // Coordinator와 통신할 명령 스트림
    let actionStream = PassthroughSubject<ARAction, Never>()

    // 바닥 인식 면적 관련
    @Published var recognizedArea: Float = 0.0
    let minRequiredArea: Float = 15.0

    // 말 선택 및 이동 후보 위치
    @Published var selectedPiece: Entity? = nil
    @Published var possibleDestinations: [String] = []

    // 윷 결과 (도:1 ~ 모:5)
    @Published var yutResult: Int = 1
}
