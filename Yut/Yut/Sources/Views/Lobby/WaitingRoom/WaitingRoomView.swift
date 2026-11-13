import SwiftUI

struct WaitingRoomView: View {
    @EnvironmentObject private var viewModel: WaitingRoomViewModel
    let room: RoomModel

    var body: some View {
        WaitingRoomLayout(title: "\(room.hostName)의 윷놀이방", buttonTitle: viewModel.buttonTitle,
            canStart: viewModel.canStartGame, onLeave: {
                if viewModel.isHost { viewModel.showLeaveAlert = true }
                else { viewModel.leaveRoom() }
            }, onStart: viewModel.startGame) {
                ForEach(viewModel.players) { player in
                    PlayerCard(name: player.name, profileImage: player.profile)
                }
                ForEach(viewModel.players.count ..< room.maxPlayers, id: \.self) { _ in
                    AddPlayerCard(systemImage: "person.fill")
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("참가 대기")
                }
            }
        .alert("방을 나가시겠습니까?", isPresented: $viewModel.showLeaveAlert) {
            Button("나가기", role: .destructive, action: viewModel.leaveRoom)
            Button("취소", role: .cancel) {}
        } message: { Text("방장이 나가면 방이 사라집니다.") }
        .navigationBarBackButtonHidden(true)
    }
}
