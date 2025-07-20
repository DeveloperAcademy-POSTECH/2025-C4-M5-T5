//
//  WinnerView.swift
//  Yut
//
//  Created by soyeonsoo on 7/18/25.
//

import SwiftUI

struct WinnerView: View {
    // TODO: - ViewModel 또는 상위 뷰에서 winnerName, winnerImageName 받아오기
    let winnerName: String = "세나"
    let winnerPieceImageName: String = "piece3_blue"
    
    var body: some View {
        DecoratedBackground{
            VStack{
                Text("\(winnerName) 승!")
                    .font(.system(size: 52, weight: .bold, design: .default))
                    .foregroundColor(.brown1)
                    .padding(.top, 24)
                Group{
                    WinnerPieceView(imageName: winnerPieceImageName)
                        .rotationEffect(.degrees(-8))
                    LoserPiecesView()
                }
                .padding(.top, 40)
                Spacer()
                BottomButtonRowView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct WinnerPieceView: View {
    let imageName: String
    
    @State private var floatUp = false
    
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 390)
            .offset(y: floatUp ? -10 : 10)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: floatUp
            )
            .shadow(color: .yellow.opacity(0.5), radius: 50, x: 0, y: 0)
            .onAppear{
                floatUp.toggle()
            }
    }
}

private struct LoserPiecesView: View {
    var body: some View {
        ZStack{
            Image("piece1_yellow")
                .resizable()
                .scaledToFit()
                .frame(width: 182)
                .rotationEffect(.degrees(18))
                .offset(x: -88, y: -90)
            
            Image("piece2_jade")
                .resizable()
                .scaledToFit()
                .frame(width: 182)
                .rotationEffect(.degrees(-3))
                .offset(x: 0, y: -40)
            
            Image("piece4_red")
                .resizable()
                .scaledToFit()
                .frame(width: 182)
                .rotationEffect(.degrees(-20))
                .offset(x: 96, y: -80)
        }
    }
}

private struct BottomButtonRowView: View {
    var body: some View {
        HStack(spacing: 10){
            Button {
                // TODO: - 홈뷰로 라우팅
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

#Preview {
    WinnerView()
}
