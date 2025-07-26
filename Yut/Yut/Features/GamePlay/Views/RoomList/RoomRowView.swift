//
//  RoomRowView.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/23/25.
//

import SwiftUI

struct RoomRowView: View {
    let room: RoomModel

    var body: some View {
        HStack {
            Text("\(room.hostName)의 윷놀이방")
                .font(.PR.title)
                .foregroundColor(.brown5)

            Spacer()

            Text("\(room.currentPlayers)/\(room.maxPlayers)")
                .font(.pretendard(.medium, size: 18))
                .foregroundColor(.brown5)
        }
        .frame(height: 82)
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

//#Preview {
//    RoomRowView()
//}
