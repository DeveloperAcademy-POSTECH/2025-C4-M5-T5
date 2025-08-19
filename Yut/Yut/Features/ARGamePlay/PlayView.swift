import ARKit
import MultipeerConnectivity
import RealityKit
import SwiftUI

struct PlayView: View {
    let arCoordinator: ARCoordinator
    
    @EnvironmentObject var viewModel: WaitingRoomViewModel
    
    // 상태 관리 객체 (AR의 현재 단계, 명령 스트림, 윷 결과 등 공유)
    @StateObject var arState = ARState()
    
    @State private var showYutGatheringSequence: Bool = false
    @State private var showFinalFrame: Bool = false
    @State private var isAnimationDone: Bool = false
    private let sound = SoundService()
    
    @State private var showThrowInstruction = true
    @State private var showThrowButton = true
    @State var showModal = true
    
    var currentPlayerSequence: Int {
        arState.gameManager.currentPlayer.sequence
    }
    
    var body: some View {
        ZStack {
            // AR 콘텐츠 뷰 (카메라, 평면 인식 등 RealityKit 기반)
            ARViewContainer(arState: arState)
                .edgesIgnoringSafeArea(.all)
                .id(arState.sessionUUID)
            
            if arState.gamePhase == .showingYutResult {
                VStack {
                    Spacer()
                    YutResultDisplay(result: arState.yutResult)
                        .frame(width: 300, height: 300)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
                .zIndex(1)
            }
            
            if showYutGatheringSequence {
                YutGatheringSequenceView(isAnimationDone: $isAnimationDone)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(3)
                    .padding(.top, 40)
            }
            
            if arState.showFinalFrame {
                GeometryReader { geometry in
                    Image("Yut.0030")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width + 60, height: geometry.size.height + 60)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .ignoresSafeArea()
                        .zIndex(2)
                        .padding(.top, 38)
                }
            }
            
            VStack {
                // 게임 상태에 따라 상단 안내 뷰 + 하단 인터랙션 UI를 함께 표시
                switch arState.gamePhase {
                    
                    // 1. 바닥 탐색 중 (아직 충분히 인식되지 않음)
                case .arSessionLoading:
                    DecoratedBackground{
                        InstructionView(text: "카메라가 켜지고 윷놀이가 시작됩니다!")
                    }.task { @MainActor in
                        arState.actionStream.send(.preloadModels)
                        
                        // MPC 목업 데이터
                        //                        let player1 = PlayerModel(name: "노랑", sequence: 1, peerID: MCPeerID(displayName: "Player1"))
                        //                        let player2 = PlayerModel(name: "초록", sequence: 2, peerID: MCPeerID(displayName: "Player2"))
                        //                        MPCManager.shared.players = [player1, player2]
                        //
                        try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
                        arState.gamePhase = .scanningPlanes
                    }
                    
                case .scanningPlanes:
                    ProgressBar(
                        text: "말판을 배치할 평면을 충분히 스캔해 주세요",
                        currentProgress: arState.recognizedArea,
                        minRequiredArea: arState.minRequiredArea
                    )
                    
                    Spacer()
                    
                    let canProceed = arState.recognizedArea >= arState.minRequiredArea
                    
                    RoundedBrownButton(title: "다음", isEnabled: canProceed) {
                        if canProceed {
                            arState.gamePhase = .placingBoard
                        }
                    }
                    
                    // 2. 사용자가 탭으로 보드를 놓는 단계
                case .placingBoard:
                    InstructionView(text: "탭해서 말판을 배치하세요")
                    Spacer()
                    EmptyView()
                    
                    // 3. 핀치/드래그로 위치/크기 조정 단계
                case .adjustingBoard:
                    InstructionView(text: "말판의 크기와 위치를 조정하세요")
                    Spacer()
                    RoundedBrownButton(title: "배치하기", isEnabled: true) {
                        arState.actionStream.send(.fixBoardPosition)
                        arState.actionStream.send(.disablePlaneVisualization)
                        arState.gamePhase = .boardConfirmed
                    }
                    
                    // 4. 보드가 확정된 상태 (게임 시작 대기)
                case .boardConfirmed:
                    EmptyView()
                    Spacer()
                    RoundedBrownButton(title: "윷놀이 시작!", isEnabled: true) {
                        arState.actionStream.send(.setupNewGame(players: viewModel.players))
                    }
                    
                    // 5. 윷 던지기 준비 단계
                case .readyToThrow:

                    VStack {
                        let currentPlayer = arState.gameManager.currentPlayer
                                                
                        if arState.showThrowButton {
                            InstructionView(text: "버튼을 누르고 기기를 흔들어 윷을 던지세요")
                            
                            Spacer()
                            
                            // 테스트용 윷 결과 버튼 (디버깅이나 임시 시연용)
//                            HStack(spacing: 10) {
//                                ForEach(YutResult.allCases) { result in
//                                    Button(result.displayText) {
//                                        // 테스트 결과를 강제로 설정 (예: 도/개/걸/윷/모)
//                                        arState.actionStream.send(.setYutResultForTesting(result))
//                                    }
//                                    .padding()
//                                    .background(Color.brown.opacity(0.8))
//                                    .foregroundColor(.white)
//                                    .cornerRadius(10)
//                                    .font(.system(size: 14, weight: .bold))
//
//                                }
//                            }

                            // 윷 던지기 버튼 표시 조건
                            YutThrowButton(sequence: currentPlayer.sequence) {
                                
                                arState.showThrowButton = false
                                showYutGatheringSequence = true
                                showFinalFrame = false
                                
                                sound.playCollectYutSound()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                                    showYutGatheringSequence = false
                                    showFinalFrame = true
                                    
                                    arState.actionStream.send(.startMonitoringMotion)
                                }
                            }
                        }
                    }.onAppear {
                        // 윷 던지기 준비 상태
                        arState.showThrowButton = true
                    }
                    
                    // 5.5 윷 던지기 결과 표시
                case .showingYutResult:
                    Spacer()
                    
                    // 6. 움직일 말 선택 단계
                case .selectingPieceToMove:
                    VStack {
                        InstructionView(text: "\(arState.gameManager.currentPlayer.name)의 턴: 움직일 말을 탭하세요.")
                        Spacer()
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
                    EmptyView()
                    
                case .promptingForCarry:
                    CarryChoiceModalView(isPresented: $showModal, arState: arState)
                }
            }
        }
        .onAppear {
            arState.sessionUUID = UUID() // 강제 리프레시 → ARView 재생성
            print("👀 viewModel object identity:", ObjectIdentifier(viewModel))
            
            print("👀 players (PlayView onAppear):", viewModel.players.map(\.name))
            
            if viewModel.players.count >= 2 {
                arCoordinator.setupNewGame(with: viewModel.players)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
