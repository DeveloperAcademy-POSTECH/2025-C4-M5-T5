//
//  WaitingRoomView.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/21/25.
//

import SwiftUI

struct WaitingRoomView: View {
    let room: Room
    private let maxPlayers = 4
    
    @State private var players: [Player] = [
        Player(name: "해피제이", color: .yellow),
        Player(name: "해피제이", color: .blue),
        Player(name: "해피제이", color: .purple)
    ]
    
    // 2명->둘이서, 3명->셋이서, 4명->넷이서
    private var buttonTitle: String {
        let mapping = [2: "둘이서", 3: "셋이서", 4: "넷이서"]
        return mapping[players.count].map { "\($0) 윷놀이 시작하기" } ?? "인원 기다리는 중..."
    }
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            ZStack {
                Text("\(room.name)의 윷놀이방").font(.pretendard(.bold, size: 24))
                    .foregroundColor(.brown4)
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.pretendard(.bold, size: 24))
                            .foregroundColor(.brown4)
                    }
                }
            }
            .padding(.top, 30)
            
            Spacer()
            
            // Player grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(players) { player in
                    PlayerCard(player: player)
                }
                ForEach(players.count ..< room.maxPlayers, id: \.self) { _ in
                    EmptyPlayerCard()
                }
            }
            
            Spacer()
            
            Button(action: startGame) {
                Text(buttonTitle)
                    .font(.pretendard(.semiBold, size: 20))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 34)
                            .fill(players.count < 2 ? Color.gray.opacity(0.2) : Color.brown4)
                    )
                    .foregroundColor(players.count < 2 ? .gray : .white)
            }
            .disabled(players.count < 2)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 16)
        .background(Color.white1.ignoresSafeArea()).navigationBarBackButtonHidden(true)
    }
    
    func startGame() {
        print("게임 시작!")
        // Start game logic here
    }
}

struct Player: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

#Preview {
    WaitingRoomView(room: Room(name: "해피제이", currentPlayers: 2, maxPlayers: 4))
}
