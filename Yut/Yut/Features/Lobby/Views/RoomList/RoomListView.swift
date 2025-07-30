//
//  WaitingRoomList.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/21/25.
//

import MultipeerConnectivity
import SwiftUI

struct RoomListView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @ObservedObject private var mpcManager = MPCManager.shared
    
    var body: some View {
        ZStack {
            Color.white1
                .ignoresSafeArea()
            
            ScrollView {
                VStack {
                    ForEach(mpcManager.availableRooms) { room in
                        //                        Button {
                        //                            navigationManager.path.append(.waitingRoom(room))
                        //                        } label: {
                        //                            RoomRowView(room: room)
                        //                        }
                        Button {
                            connectToHost(room: room)
                            navigationManager.push(.waitingRoom(room))
                        } label: {
                            RoomRowView(room: room)
                        }
                    }
                    .padding(.bottom, 12)
                    
                    Spacer()
                }
                .padding(.top, 40)
            }
        }
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.width > 80 {
                    navigationManager.pop()
                }
            }
        )
//        .onDisappear {
//            MPCManager.shared.disconnect()
//            MPCManager.shared.players.removeAll()
//        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.white1, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    navigationManager.pop()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.brown1)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("주변 윷놀이방 참여하기")
                    .font(.pretendard(.bold, size: 20))
                    .foregroundColor(.brown5)
                //                    .padding(.top, 29)
                //                    .padding(.bottom,29) 이거 2개 실선 사라지면 반영해야 할 패딩값
            }
        }
    }
    
    private func connectToHost(room: RoomModel) {
        guard let browser = mpcManager.browser else {
            print("❗️browser is nil")
            return
        }
        guard let session = mpcManager.session else {
            print("❗️session is nil")
            return
        }
        
        let peerID = MCPeerID(displayName: room.hostName)
        print("Guest가 연결 시도하는 PeerID: \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        print("🔗 Guest: \(room.hostName)의 방에 연결 시도 중...")
    }
}

//#Preview {
//    RoomListView()
//        .environmentObject(NavigationManager())
//}
