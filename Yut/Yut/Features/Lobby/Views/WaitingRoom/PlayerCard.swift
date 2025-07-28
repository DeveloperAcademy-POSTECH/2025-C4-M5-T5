//
//  PlayerCard.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/21/25.
//

import SwiftUI

struct PlayerCard: View {
    let player: PlayerModel
    
    var body: some View {
        VStack {
            Image(player.profile)
                .resizable()
                .scaledToFill()
                .frame(width: 135, height: 135)
                .clipShape(Circle())
                .padding(.top, 64)
                .padding(.bottom, 25)

            Text(player.name)
                .font(.pretendard(.bold, size: 24))
                .foregroundColor(.brown4)
                .padding(.bottom, 16)
        }
        .frame(
            width: UIScreen.main.bounds.width / 2 - 24,
            height: 289
        )
        .background(.white.opacity(0.35))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        )
    }
}

//#Preview {
//    PlayerCard(player: PlayerModel(name: "sena", sequence: 1, peerID: MCPeerID(displayName: "sena")))
//}
