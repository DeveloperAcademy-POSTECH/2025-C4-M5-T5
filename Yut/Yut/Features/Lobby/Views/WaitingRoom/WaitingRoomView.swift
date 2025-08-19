//
//  WaitingRoomView.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/21/25.
//

import MultipeerConnectivity
import SwiftUI

struct WaitingRoomView: View {
    let room: RoomModel
    let arCoordinator: ARCoordinator
    
    private let maxPlayers = 4
    
    @EnvironmentObject private var viewModel: WaitingRoomViewModel
    
    @EnvironmentObject private var navigationManager: NavigationManager
    @State private var isNavigatingToPlayView = false
    
    @State private var showNicknameModal = false
    @State private var newNickname = ""
    
    @State private var isGameStarting = false
    
    init(room: RoomModel, navigationManager: NavigationManager, arCoordinator: ARCoordinator) {
        self.room = room
        self.arCoordinator = arCoordinator
    }
    
    var body: some View {
        ZStack{
            VStack {
                ZStack {
                    Text("\(room.hostName)의 윷놀이방")
                        .font(.pretendard(.bold, size: 24))
                        .foregroundColor(.brown4)
                    
                    HStack {
                        Spacer()
                        
                        // MARK: 닫기 (MPC 세션 종료)
                        
                        Button(action: {
                            if viewModel.isHost {
                                viewModel.showLeaveAlert = true
                            } else {
                                viewModel.leaveRoom()
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.pretendard(.bold, size: 24))
                                .foregroundColor(.brown4)
                                .padding(.trailing, 5)
                        }
                    }
                }
                .padding(.top, 30)
                
                Spacer()
                
                // Player grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(viewModel.players) { player in
                        PlayerCard(player: player)
                    }
                    ForEach(viewModel.players.count ..< room.maxPlayers, id: \.self) { _ in
                        Button(action: {
                            showNicknameModal = true
                        }) {
                            AddPlayerCard(){}
                        }
                    }
                }
                
                Spacer()
                
                Button(action: startGame) {
                    Text(viewModel.buttonTitle)
                        .font(.pretendard(.semiBold, size: 20))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 34)
                                .fill(viewModel.players.count < 2 ? Color.gray.opacity(0.2) : Color.brown4)
                        )
                        .foregroundColor(viewModel.players.count < 2 ? .gray : .white)
                }
                .disabled(viewModel.players.count < 2)
                .padding(.bottom, 20)
            }
            if showNicknameModal {
                AddPlayerModalView(isPresented: $showNicknameModal, nickname: $newNickname) {
                    viewModel.addPlayer(named: newNickname)
                }
                .zIndex(10)
            }
        }
        .padding(.horizontal, 20)
        .background(Color.white1.ignoresSafeArea())
        .alert("방을 나가시겠습니까?", isPresented: $viewModel.showLeaveAlert) {
            Button("나가기", role: .destructive) {
                viewModel.leaveRoom()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("방장이 나가면 방이 사라집니다.")
        }
        .navigationBarBackButtonHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: .gameStarted)) { _ in
            isNavigatingToPlayView = true
        }
        .onChange(of: viewModel.players) { players in
            
            if players.count >= 2 && isGameStarting {
                arCoordinator.setupNewGame(with: players)
                navigationManager.push(.playView)
                isGameStarting = false
            }
        }
        .background(
            NavigationLink(
                destination: PlayView(arCoordinator: arCoordinator)
                    .environmentObject(viewModel),
                isActive: $isNavigatingToPlayView
            ) {
                EmptyView()
            }
        )
    }
    
    func startGame() {
        // Host가 게임 시작 신호를 보내는 로직
        //        if viewModel.isHost {
        //            // MPCManager를 통해 게임 시작 신호 전송
        //            MPCManager.shared.sendStartGameSignal()
        //        }
        //        navigationManager.push(.playView)
        if viewModel.players.count >= 2 {
            isGameStarting = true
            arCoordinator.setupNewGame(with: viewModel.players)
            navigationManager.push(.playView)
        }
    }
}

//#Preview {
//    WaitingRoomView(room: RoomModel(roomName: "해피제이의 윷놀이방", hostName: "해피제이", players: []), navigationManager: NavigationManager())
//}
