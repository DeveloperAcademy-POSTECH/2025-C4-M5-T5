// MARK: - 게임 상태(단계) 정의

enum GamePhase {
    
    // 초기 설정 단계
    case searchingForSurface        // 1단계: 바닥을 인식하는 중
    case placeBoard                 // 2단계: 평면에 윷판 배치
    case adjustingBoard             // 3단계: 윷판 위치 및 크기 조절
    case boardConfirmed             // 4단계: 윷판 확정 및 게임 시작 대기
    
    // 게임 진행 단계
    case readyToThrow               // 5단계: 윷 던지기 준비
    case showingYutResult           // 5.5단계: 윷 던지기 결과 표시
    case selectingPieceToMove       // 6단계: 말을 선택하는 중
    case selectingDestination       // 7단계: 말의 이동 위치 선택
    // case pieceMoved              // (예정) 8단계: 말 이동 완료
    
}
