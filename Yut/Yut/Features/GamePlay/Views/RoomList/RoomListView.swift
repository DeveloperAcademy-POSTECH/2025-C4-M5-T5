//
//  WaitingRoomList.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/21/25.
//

import SwiftUI
import MultipeerConnectivity

struct RoomListView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @ObservedObject private var mpcManager = MPCManager.shared

    var body: some View {
        ZStack {
            Color.white1
                .edgesIgnoringSafeArea(.all)
            VStack {
                ForEach(mpcManager.availableRooms) { room in
                    Button {
                        navigationManager.path.append(.waitingRoom(room))
                    } label: {
                        RoomRowView(room: room)
                    }
                }
                .padding(.bottom, 12)

                Spacer()
            }
            .padding(.top, 40)
            .padding(.horizontal, 16)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
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
                    .font(.pretendard(.bold, size: 24))
                    .foregroundColor(.brown5)
            }
        }
        
    }
}

#Preview {
    RoomListView()
        .environmentObject(NavigationManager())
}
