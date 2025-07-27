//
//  WinnerView.swift
//  Yut
//
//  Created by soyeonsoo on 7/18/25.
//

import SwiftUI

struct WinnerView: View {
    // TODO: - ViewModel 또는 상위 뷰에서 winnerName, winnerPieceType 받아오기
    
    let winnerName: String
    let winnerPieceType: PieceType
    
    @StateObject private var navigationManager = NavigationManager()
    
    init(
        winnerName: String = "세나",
        winnerPieceType: PieceType = .blue
    ) {
        self.winnerName = winnerName
        self.winnerPieceType = winnerPieceType
    }
    
    private var backgroundColor: Color {
        winnerPieceType.backgroundColor
    }
    
    private var textColor: Color {
        winnerPieceType.textColor
    }
    
    var body: some View {
        DecoratedBackground(backgroundColor: backgroundColor){
            VStack{
                Text("\(winnerName) 승!")
                    .font(.pretendard(.semiBold, size: 48))
                    .foregroundColor(textColor)
                    .padding(.top, 28)
                WinnerPieceView(pieceType: winnerPieceType)
                    .rotationEffect(.degrees(-8))
                    .padding(.top, 40)
                LoserPiecesView(excluding: winnerPieceType)
                    .padding(.top, 40)
                Spacer()
                BottomButtonRowView(navigationManager: navigationManager)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct WinnerPieceView: View {
    let pieceType: PieceType
    
    @State private var floatUp = false
    
    var body: some View {
        Image(pieceType.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 390)
            .offset(y: floatUp ? -10 : 28)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: floatUp
            )
            .shadow(color: .white.opacity(0.8), radius: 50, x: 0, y: 0)
            .onAppear{
                floatUp = true
            }
    }
}

private struct LoserPiecesView: View {
    let excluding: PieceType
    
    var body: some View {
        let losers = PieceType.allCases.filter { $0 != excluding }
        ZStack {
            ForEach(Array(losers.enumerated()), id: \.element) { index, piece in
                Image(piece.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 182)
                    .rotationEffect(.degrees(rotation(for: index)))
                    .offset(offset(for: index))
            }
        }
    }
    
    private func rotation(for index: Int) -> Double {
        [18, -3, -20][index]
    }
    
    private func offset(for index: Int) -> CGSize {
        [CGSize(width: -88, height: -90),
         CGSize(width: 0, height: -40),
         CGSize(width: 96, height: -80)][index]
    }
}

private struct BottomButtonRowView: View {
    @ObservedObject var navigationManager: NavigationManager
    
    var body: some View {
        HStack(spacing: 10){
            Button {
                navigationManager.path.removeAll()
            } label: {
                Text("끝내기")
                    .frame(maxWidth: .infinity, maxHeight: 70)
                    .background(.brown1)
                    .foregroundColor(.white1)
                    .font(.system(size: 20, weight: .semibold))
                    .cornerRadius(34)
            }
            Button {
                // TODO: - 게임 다시 시작
                
            } label: {
                Text("한 판 더!")
                    .frame(maxWidth: .infinity, maxHeight: 70)
                    .background(.brown1)
                    .foregroundColor(.white1)
                    .font(.system(size: 20, weight: .semibold))
                    .cornerRadius(34)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 70)
    }
}

//#Preview {
//    WinnerView(
//        winnerName: "노터",
//        winnerPieceType: .blue
//    )
//}
