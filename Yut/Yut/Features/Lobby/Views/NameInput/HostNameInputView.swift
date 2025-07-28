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
                    MPCManager.shared.updatePeerIDAndSession(with: host_nickname)
                    MPCManager.shared.addHostPlayer(name: host_nickname)
                    MPCManager.shared.configurePeerAndSession(with: host_nickname)
                    MPCManager.shared.startAdvertising()
                    MPCManager.shared.sendPlayersUpdate()
                   
                    if let newRoom = MPCManager.shared.availableRooms.first(where: { $0.hostName == host_nickname }) {
                        navigationManager.path.append(.waitingRoom(newRoom))
                    }
                },
                autoFocus: true
            )
        }
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.width > 80 {
                    navigationManager.pop()
                }
            }
        )
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
