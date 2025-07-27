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
    
    private let maxPlayers = 4
    let imageNames = ["prc1", "prc2", "prc3", "prc4"]
 
    //    @State private var players: [Player] = [
    //        Player(
    //            name: "해피제이",
    //            imageName: "prc1",
    //            sequence: 1,
    //            peerID: MCPeerID(displayName: "해피제이")
    //        ),
    //        Player(
    //            name: "세나",
    //            imageName: "prc2",
    //            sequence: 2,
    //            peerID: MCPeerID(displayName: "세나")
    //        )
    //    ]
    
    @ObservedObject private var mpcManager = MPCManager.shared
    // MPCManager의 전역 players 배열을 그대로 참조

    private func addPlayer(name: String) {
        let index = mpcManager.players.count
        guard index < imageNames.count else { return }

        Task {  // 새로운 비동기 컨텍스트 시작
            let newPlayer = await PlayerModel.load(
                name: name,
                sequence: index + 1,
                peerID: MCPeerID(displayName: name),
                isHost: false
            )

            DispatchQueue.main.async {
                mpcManager.players.append(newPlayer)
                if mpcManager.isHost {
                    mpcManager.sendPlayersUpdate()
                }
            }
        }
    }
    
    // 2명->둘이서, 3명->셋이서, 4명->넷이서
    private var buttonTitle: String {
        let mapping = [2: "둘이서", 3: "셋이서", 4: "넷이서"]
        return mapping[mpcManager.players.count].map { "\($0) 윷놀이 시작하기" } ?? "인원 기다리는 중..."
    }
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            ZStack {
                Text("\(room.hostName)의 윷놀이방")
                    .font(.pretendard(.bold, size: 24))
                    .foregroundColor(.brown4)
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.pretendard(.bold, size: 24))
                            .foregroundColor(.brown4)
                    }
                }
            }
            .padding(.top, 30)
            
            Spacer()
            
            // Player grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(mpcManager.players) { player in
                    PlayerCard(player: player)
                }
                ForEach(mpcManager.players.count ..< room.maxPlayers, id: \.self) { _ in
                    EmptyPlayerCard()
                }
            }
            
            Spacer()
            
            Button(action: startGame) {
                Text(buttonTitle)
                    .font(.pretendard(.semiBold, size: 20))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 34)
                            .fill(mpcManager.players.count < 2 ? Color.gray.opacity(0.2) : Color.brown4)
                    )
                    .foregroundColor(mpcManager.players.count < 2 ? .gray : .white)
            }
            .disabled(mpcManager.players.count < 2)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 16)
        .background(Color.white1.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
    
    func startGame() {
        print("게임 시작!")
        // Start game logic here
    }
}

//struct Player: Identifiable {
//    let id = UUID()
//    let name: String
//    let imageName: String
//}

#Preview {
    WaitingRoomView(room: RoomModel(roomName: "해피제이의 윷놀이방", hostName: "해피제이", players: []))
}
