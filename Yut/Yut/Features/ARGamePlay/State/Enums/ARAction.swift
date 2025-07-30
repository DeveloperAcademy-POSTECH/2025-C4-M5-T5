// MARK: - Coordinator에게 전달할 명령 정의

enum ARAction {
    case fixBoardPosition                   // 윷판을 평면 위에 고정
    case disablePlaneVisualization          // 평면 시각화 비활성화
    case showDestinationsForNewPiece        // 새 말 놓을 위치 하이라이트
    case setupNewGame(players: [PlayerModel]) // 새 게임 시작
    case preloadModels                      // 에셋 미리 선언
    case startMonitoringMotion              // 윷 던지기 감지 시작 (CoreMotion)
    case setYutResultForTesting(YutResult)  // 테스트용 윷 결과 생성
}
