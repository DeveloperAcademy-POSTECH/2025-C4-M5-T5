import SwiftUI
import RealityKit
import ARKit

struct PlayView : View {
    // 상태 관리 객체 (AR의 현재 단계, 명령 스트림, 윷 결과 등 공유)
    @StateObject var arState = ARState()
    @State private var showGatheringVideo: Bool = false
    
    var body: some View {
        ZStack {
            // AR 콘텐츠 뷰 (카메라, 평면 인식 등 RealityKit 기반)
            ARViewContainer(arState: arState)
                .edgesIgnoringSafeArea(.all)
            
            if arState.gamePhase == .showingYutResult {
                VStack {
                    Spacer()
                    YutResultDisplay(result: arState.yutResult)
                        .frame(width: 300, height: 300)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
                .zIndex(999)
            }
            
//            if showGatheringVideo {
//                YutGatheringVideoView()
//                    .ignoresSafeArea()
//                    .transition(.opacity)
//                    .zIndex(10)
//            }
            
            VStack {
                // 게임 상태에 따라 상단 안내 뷰 + 하단 인터랙션 UI를 함께 표시
                switch arState.gamePhase {
                    
                    // 1. 바닥 탐색 중 (아직 충분히 인식되지 않음)
                case .searchingForSurface:
                    ProgressBar(
                        text: "바닥을 충분히 색칠해 주세요.",
                        currentProgress: arState.recognizedArea,
                        minRequiredArea: arState.minRequiredArea
                    )
                    Spacer()
                    let canProceed = arState.recognizedArea >= arState.minRequiredArea
                    RoundedBrownButton(title: "다음", isEnabled: canProceed) {
                        if canProceed {
                            arState.gamePhase = .placeBoard
                        }
                    }
                    
                    // 2. 사용자가 탭으로 보드를 놓는 단계
                case .placeBoard:
                    InstructionView(text: "탭해서 말판을 배치하세요.")
                    Spacer()
                    EmptyView() // 버튼 없음
                    
                    // 3. 핀치/드래그로 위치/크기 조정 단계
                case .adjustingBoard:
                    InstructionView(text: "핀치와 드래그로\n보드의 크기와 위치를 조정하세요.")
                    Spacer()
                    // 보드 확정 및 시각화 종료
                    RoundedBrownButton(title: "여기에 배치", isEnabled: true) {
                        arState.actionStream.send(.fixBoardPosition)
                        arState.actionStream.send(.disablePlaneVisualization)
                        arState.actionStream.send(.preloadYutModels)
                        arState.gamePhase = .boardConfirmed
                    }
                    
                    // 4. 보드가 확정된 상태 (게임 시작 대기)
                case .boardConfirmed:
                    EmptyView() // 상단 안내 없음
                    Spacer()
                    RoundedBrownButton(title: "윷놀이 시작!", isEnabled: true) {
                        arState.actionStream.send(.setupNewGame)
                    }
                    
                    // 5. 윷 던지기 준비 단계
                case .readyToThrow:
                    InstructionView(text: "버튼을 눌러 윷을 던져랏")
                    Spacer()
                    RoundedBrownButton(title: "윷 던지기 활성화!", isEnabled: true) {
                        //                        showGatheringVideo = true
                        //
                        //                        // 영상 재생 도중 다른 동작 방지 위해 잠시 지연 후 실제 액션 실행
                        //                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        //                                arState.actionStream.send(.startMonitoringMotion)
                        //                                showGatheringVideo = false
                        //                            }
                        arState.actionStream.send(.startMonitoringMotion)
                        
                    }
                    
                    // 5.5 윷 던지기 결과 표시
                case .showingYutResult:
                    Spacer()
                    
                    // 6. 움직일 말 선택 단계
                case .selectingPieceToMove:
                    VStack {
                        InstructionView(text: "\(arState.gameManager.currentPlayer.name)의 턴: 움직일 말을 탭하세요.")
                        Spacer()
                        
                        // 만약 현재 플레이어가 판 밖에 둔 말이 있다면, '새 말 놓기' 버튼을 보여줍니다.
                        if arState.gameManager.currentPlayerHasOffBoardPieces {
                            RoundedBrownButton(title: "새 말 놓기", isEnabled: true) {
                                arState.actionStream.send(.showDestinationsForNewPiece)
                            }
                        }
                    }
                    
                    // 7. 말의 이동 목적지 선택 단계
                case .selectingDestination:
                    InstructionView(text: "말을 옮길 곳을 선택하세요.")
                    Spacer()
                    EmptyView() // 버튼 없음
                }
            }
        }
    }
}
