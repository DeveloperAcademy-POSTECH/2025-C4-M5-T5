//
//  WinnerView.swift
//  YUT
//
//  Created by soyeonsoo on 7/18/25.
//

import SwiftUI

struct WinnerView: View {
    @ObservedObject var viewModel: WinnerViewModel
    private var winnerName: String { viewModel.winnerName }
    private var winnerPieceType: PieceType { viewModel.winnerPieceType }

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
                BottomButtonRowView(onFinish: viewModel.finishGame, onPlayAgain: viewModel.playAgain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

//#Preview {
//    WinnerView(
//        winnerName: "노터",
//        winnerPieceType: .blue
//    )
//}
