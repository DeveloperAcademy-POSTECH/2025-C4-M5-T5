//
//  GuestNameInputView.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/21/25.
//

import SwiftUI
import MultipeerConnectivity

struct GuestNameInputView: View {
    @State private var guest_nickname: String = ""
    @EnvironmentObject private var navigationManager: NavigationManager

    var body: some View {
        ZStack {
            Color("White1")
                .ignoresSafeArea()

            NameInputFormView(
                title: "닉네임을 입력해주세요",
                nickname: $guest_nickname,
                onSubmit: {
                    let guestName = guest_nickname.trimmingCharacters(in: .whitespaces)
                    if !guestName.isEmpty {
                        MPCManager.shared.isHost = false
                        MPCManager.shared.updatePeerIDAndSession(with: guestName)
//                        MPCManager.shared.addGuestPlayer(peerID: MCPeerID(displayName: guestName))
                        MPCManager.shared.myPeerID = MCPeerID(displayName: guestName)
                        MPCManager.shared.configurePeerAndSession(with: guestName)
                        MPCManager.shared.startBrowsing()
                        navigationManager.path.append(.roomList(guestName))
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
                Button {
                    navigationManager.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.brown1)
                }
            }
        }
    }
}

#Preview {
    GuestNameInputView()
}
