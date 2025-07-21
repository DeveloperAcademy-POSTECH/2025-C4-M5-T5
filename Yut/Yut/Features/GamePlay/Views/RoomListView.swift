//
//  WaitingRoomList.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/21/25.
//

import SwiftUI

struct Room: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let currentPlayers: Int
    let maxPlayers: Int
}

struct RoomListView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    
    // 예제 데이터
    let rooms: [Room] = [
        Room(name: "해피제이의 윷놀이방", currentPlayers: 2, maxPlayers: 4),
        Room(name: "네이선의 윷놀이방", currentPlayers: 1, maxPlayers: 4),
        Room(name: "엠케이의 윷놀이방", currentPlayers: 3, maxPlayers: 4),
        Room(name: "사야의 윷놀이방", currentPlayers: 2, maxPlayers: 4)
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
            .padding(.top, 48)
            .padding(.horizontal, 16)
        }
    }
}

struct RoomRowView: View {
    let room: Room

    var body: some View {
        HStack {
            Text(room.name)
                .font(.PR.title)

            Spacer()

            Text("\(room.currentPlayers)/\(room.maxPlayers)")
                .font(.pretendard(.medium, size: 18))
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(
            ZStack {
                Color.white.opacity(0.15)

                RoundedRectangle(cornerRadius: 34)
                    .stroke(
                        Color("Brown5").opacity(0.2),
                        lineWidth: 1
                    )
                    .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
            }
        )
    }
}

#Preview {
    RoomListView()
        .environmentObject(NavigationManager())
}
