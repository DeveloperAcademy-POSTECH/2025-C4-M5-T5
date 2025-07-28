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
//                .edgesIgnoringSafeArea(.all)
                .ignoresSafeArea()
            ScrollView {
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
        }
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.width > 80 {
                    navigationManager.pop()
                }
            }
        )
        .onDisappear {
            MPCManager.shared.disconnect()
            MPCManager.shared.players.removeAll()
        }
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
