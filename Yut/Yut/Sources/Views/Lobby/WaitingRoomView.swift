import SwiftUI

struct WaitingRoomView: View {
    @EnvironmentObject private var viewModel: WaitingRoomViewModel
    @State private var showNicknameModal = false
    @State private var newNickname = ""
    let room: RoomModel

    var body: some View {
        ZStack {
            VStack {
                WaitingRoomHeader(title: "\(room.hostName)의 윷놀이방") {
                    if viewModel.isHost { viewModel.showLeaveAlert = true }
                    else { viewModel.leaveRoom() }
                }
                .padding(.top, 30)
                Spacer()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(viewModel.players) { player in
                        PlayerCard(name: player.name, profileImage: player.profile)
                    }
                    ForEach(viewModel.players.count ..< room.maxPlayers, id: \.self) { _ in
                        Button { showNicknameModal = true } label: { AddPlayerCard() }
                            .buttonStyle(.plain)
                            .accessibilityLabel("플레이어 추가")
                    }
                }
                Spacer()
                ActionButton(title: viewModel.buttonTitle, isEnabled: viewModel.canStartGame, action: viewModel.startGame)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            if showNicknameModal {
                AddPlayerModalView(isPresented: $showNicknameModal, nickname: $newNickname) {
                    viewModel.addPlayer(named: newNickname)
                }
                .zIndex(10)
            }
        }
        .background(ThemeColors.canvas.ignoresSafeArea())
        .alert("방을 나가시겠습니까?", isPresented: $viewModel.showLeaveAlert) {
            Button("나가기", role: .destructive, action: viewModel.leaveRoom)
            Button("취소", role: .cancel) {}
        } message: { Text("방장이 나가면 방이 사라집니다.") }
        .navigationBarBackButtonHidden(true)
    }
}
