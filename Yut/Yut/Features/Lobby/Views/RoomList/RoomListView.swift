//
//  WaitingRoomList.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/21/25.
//

import SwiftUI



struct RoomListView: View {
    @EnvironmentObject private var navigationManager: NavigationManager

    // 예제 데이터
    let rooms: [Room] = [
        Room(name: "해피제이", currentPlayers: 2, maxPlayers: 4),
        Room(name: "네이선", currentPlayers: 1, maxPlayers: 4),
        Room(name: "엠케이", currentPlayers: 3, maxPlayers: 4),
        Room(name: "사야", currentPlayers: 2, maxPlayers: 4)
    ]

    var body: some View {
        ZStack {
            Color.white1
                .edgesIgnoringSafeArea(.all)
            VStack {
                ForEach(rooms) { room in
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
