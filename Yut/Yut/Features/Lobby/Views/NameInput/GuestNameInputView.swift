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
    @ObservedObject private var mpcManager = MPCManager.shared

    @State private var didConnect = false

    var body: some View {
        ZStack {
            Color("White1")
                .ignoresSafeArea()
                .onTapGesture {
                    self.endTextEditing()
                }

            VStack {
                NameInputFormView(
                    title: "닉네임을 입력해주세요",
                    nickname: $guest_nickname,
                    onSubmit: {
                        let guestName = guest_nickname.trimmingCharacters(in: .whitespaces)
                        if !guestName.isEmpty {
                            MPCManager.shared.isHost = false
                            MPCManager.shared.configurePeerAndSession(with: guestName)
                            MPCManager.shared.startBrowsing()
                            // RoomListView로 이동하지 않고, 아래에서 자동 연결
                        }
                    },
                    autoFocus: true
                )
            }
        }
        .onChange(of: mpcManager.availableRooms) { rooms in
            guard !didConnect, let firstRoom = rooms.first else { return }
            didConnect = true
            connectToHost(room: firstRoom)
            navigationManager.path.append(.waitingRoom(firstRoom))
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

    private func connectToHost(room: RoomModel) {
        guard let browser = mpcManager.browser else { return }
        guard let session = mpcManager.session else { return }
        let peerID = MCPeerID(displayName: room.hostName)
        print("Guest가 연결 시도하는 PeerID: \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        print("🔗 Guest: \(room.hostName)의 방에 연결 시도 중...")
    }
}

#Preview {
    GuestNameInputView()
}

//
//import SwiftUI
//import MultipeerConnectivity
//
extension View {
    func endTextEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
//
//struct GuestNameInputView: View {
//    @State private var guest_nickname: String = ""
//    @EnvironmentObject private var navigationManager: NavigationManager
//
//    var body: some View {
//        ZStack {
//            Color("White1")
//                .ignoresSafeArea()
//                .onTapGesture {
//                    self.endTextEditing()
//                }
//
//            VStack {
//                NameInputFormView(
//                    title: "닉네임을 입력해주세요",
//                    nickname: $guest_nickname,
//                    onSubmit: {
//                        let guestName = guest_nickname.trimmingCharacters(in: .whitespaces)
//                        if !guestName.isEmpty {
//                            MPCManager.shared.isHost = false
//                            MPCManager.shared.configurePeerAndSession(with: guestName)
//                            MPCManager.shared.startBrowsing()
//                            navigationManager.path.append(.roomList(guestName))
//                        }
//                    },
////                    onSubmit: {
////                        let guestName = guest_nickname.trimmingCharacters(in: .whitespaces)
////                        if !guestName.isEmpty {
////                            MPCManager.shared.isHost = false
////                            MPCManager.shared.updatePeerIDAndSession(with: guestName)
////                            MPCManager.shared.myPeerID = MCPeerID(displayName: guestName)
////                            MPCManager.shared.configurePeerAndSession(with: guestName)
////                            MPCManager.shared.startBrowsing()
////                            navigationManager.path.append(.roomList(guestName))
////                        }
////                    },
//                    autoFocus: true
//                )
//            }
//        }
//        .gesture(
//            DragGesture().onEnded { value in
//                if value.translation.width > 80 {
//                    navigationManager.pop()
//                }
//            }
//        )
//        .navigationBarBackButtonHidden(true)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button {
//                    navigationManager.pop()
//                } label: {
//                    Image(systemName: "chevron.left")
//                        .foregroundColor(.brown1)
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    GuestNameInputView()
//}
