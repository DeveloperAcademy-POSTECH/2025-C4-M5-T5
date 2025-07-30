//
//  CarryChoiceModalView.swift
//  Yut
//
//  Created by soyeonsoo on 7/30/25.
//

import SwiftUI

struct CarryChoiceModalView: View {
    @Binding var isPresented: Bool
    @ObservedObject var arState: ARState
    
    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }
                
                VStack(spacing: 20) {
                    Text("두 말이 한 곳에서 만났어요!\n업을까요?")
                        .multilineTextAlignment(.center)
                        .font(.pretendard(.semiBold, size: 22))
                        .padding(.top, 24)
                        .padding(.bottom, 4)
                        .lineSpacing(6)
                    
                    HStack(spacing: 12) {
                        Button("따로 가기") {
                            // TODO: - 로직 연결
                            arState.actionStream.send(.resolveMove(carry: false))
                            isPresented = false
                        }
                        .frame(maxWidth: .infinity, maxHeight: 70)
                        .background(.brown1.opacity(0.8))
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold)) // ← 폰트 크기 및 굵기
                        .cornerRadius(36)
                        
                        Button("업기") {
                            arState.actionStream.send(.resolveMove(carry: true))
                            isPresented = false
                        }
                        .frame(maxWidth: .infinity, maxHeight: 70)
                        .background(.brown1.opacity(0.8))
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold))
                        .cornerRadius(36)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(.ultraThinMaterial.opacity(0.8))
                .background(.white1.opacity(0.8))
                .cornerRadius(36)
                .overlay(
                    RoundedRectangle(cornerRadius: 36)
                        .stroke(.white, lineWidth: 1.5)
                )
                .padding(20)
                .shadow(color: .brown1.opacity(0.2), radius: 18, x: 0, y: 0)
            }
        }
    }
}

//#Preview {
//    CarryChoiceModalExample()
//}
//
//// PreView용 테스트 뷰
//struct CarryChoiceModalExample: View {
//    @State private var showModal = false
//
//    var body: some View {
//        ZStack {
//            VStack(spacing: 20) {
//                Text("~ 윷놀이 중 ~")
//                    .font(.title)
//                Button("업을지 말지 선택 모달 띄우기") {
//                    showModal = true
//                }
//            }
//            CarryChoiceModalView(isPresented: $showModal)
//        }
//    }
//}
