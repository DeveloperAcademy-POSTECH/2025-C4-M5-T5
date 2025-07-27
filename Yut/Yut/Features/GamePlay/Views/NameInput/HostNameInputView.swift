//HostNameInputView.swift
//  HostNameInputView.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/17/25.
//

import SwiftUI
import MultipeerConnectivity

struct HostNameInputView: View {
    @State private var host_nickname: String = ""
    @EnvironmentObject private var navigationManager: NavigationManager

    var body: some View {
        ZStack {
            Color("White1")
                .ignoresSafeArea()
            NameInputFormView(
                title: "닉네임을 입력해주세요",
                nickname: $host_nickname,
                onSubmit: {
                    MPCManager.shared.isHost = true
                    MPCManager.shared.myPeerID = MCPeerID(displayName: host_nickname)
                    MPCManager.shared.addHostPlayer(name: host_nickname)
                    MPCManager.shared.startAdvertising()
                    MPCManager.shared.sendPlayersUpdate()
                    let newRoom = RoomModel(
                        roomName: "\(host_nickname)의 윷놀이방",
                        hostName: host_nickname,
                        players: MPCManager.shared.players
                    )
                    MPCManager.shared.availableRooms.append(newRoom)

                    if let hostPlayer = MPCManager.shared.players.first {
                        navigationManager.path.append(.waitingRoom(newRoom))
                    }
                },
                autoFocus: true
            )
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    navigationManager.pop()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.brown1)
                }
            }
        }
    }
}

#Preview {
    HostNameInputView()
}

////
////  HostNameInputView.swift
////  Yut
////
////  Created by Hwnag Seyeon on 7/17/25.
////
//
//import SwiftUI
//
//struct HostNameInputView: View {
//    @State private var host_nickname: String = ""
//    @EnvironmentObject private var navigationManager: NavigationManager
//
//    var body: some View {
//        ZStack {
//            Color("White1")
//                .ignoresSafeArea()
//            NameInputFormView(
//                title: "닉네임을 입력해주세요",
//                nickname: $host_nickname,
//                onSubmit: {
//                    let newRoom = Room(
//                        name: host_nickname,
//                        currentPlayers: 1,
//                        maxPlayers: 4
//                    )
//                    navigationManager.path.append(.waitingRoom(newRoom))
//                },
//                autoFocus: true
//            )
//        }
//        .navigationBarBackButtonHidden(true)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button(action: {
//                    navigationManager.pop()
//                }) {
//                    Image(systemName: "chevron.left")
//                        .foregroundColor(.brown1)
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    HostNameInputView()
//}
