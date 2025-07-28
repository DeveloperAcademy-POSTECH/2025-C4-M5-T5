// MARK: - Coordinator에게 전달할 명령 정의

enum ARAction {
    case fixBoardPosition                // 윷판을 평면 위에 고정
    case disablePlaneVisualization      // 평면 시각화 비활성화
    case setupNewGame                   // 게임 시작
    case showDestinationsForNewPiece    // ✨ '새 말'의 경로를 보여달라는 명확한 액션
//    case showDestinationsForExistingPiece // 기존 말 이동 가능 위치 하이라이트
    case startMonitoringMotion          // 윷 던지기 감지 시작 (CoreMotion)
}
