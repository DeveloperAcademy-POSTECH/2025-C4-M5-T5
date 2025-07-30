//
//  AddPlayerModalView.swift
//  Yut
//
//  Created by soyeonsoo on 7/30/25.
//

import SwiftUI

struct AddPlayerModalView: View {
    @Binding var isPresented: Bool
    @Binding var nickname: String
    
    var onSubmit: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .padding(.horizontal, -20)
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 20) {
                Text("닉네임을 입력하세요")
                    .font(.pretendard(.regular, size: 22))
                    .padding(.top, 32)

                TextField("", text: $nickname)
                    .frame(width: 218, height: 34)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.14))
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.brown, lineWidth: 1)
                        }
                    )
                    .onChange(of: nickname) {
                        if $0.count > 10 {
                            nickname = String($0.prefix(10))
                        }
                    }
                
                Button("추가") {
                    onSubmit()
                    isPresented = false
                    nickname = ""
                }
                .disabled(nickname.isEmpty)
                .frame(maxWidth: .infinity, maxHeight: 50)
                .background(nickname.isEmpty ? Color.gray.opacity(0.3) : Color.brown4)
                .foregroundColor(.white)
                .cornerRadius(25)
                .padding(.horizontal, 30)
                .padding(.bottom, 24)
            }
            .background(.ultraThinMaterial.opacity(0.8))
            .background(.white1.opacity(0.8))
            .cornerRadius(24)
            .padding(18)
            .shadow(radius: 8)
            .transition(.scale)
            HStack {
                Spacer()
                Text("\(nickname.count)/10")
                    .font(.system(size: 15))
                    .foregroundColor(.brown5)
            }
            .padding(.trailing, 62)
            .padding(.bottom, 18)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: isPresented)
    }
}
