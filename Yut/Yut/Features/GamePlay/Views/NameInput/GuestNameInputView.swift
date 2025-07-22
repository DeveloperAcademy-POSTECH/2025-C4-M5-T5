//
//  GuestNameInputView.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/21/25.
//

import SwiftUI

struct GuestNameInputView: View {
    @State private var guest_nickname: String = ""
    @FocusState private var isFocused: Bool
    @StateObject private var keyboard = KeyboardObserver()
    @EnvironmentObject private var navigationManager: NavigationManager
    
    var body: some View {
        ZStack {
            Color("White1")
                .ignoresSafeArea()
            VStack {
                VStack(alignment: .leading, spacing: 32) {
                    Text("닉네임을 입력해주세요")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.brown1)
                        .padding(.top, 20)
                    
                    // 닉네임 입력창
                    ZStack(alignment: .leading) {
                        if guest_nickname.isEmpty {
                            Text("닉네임")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.brown5)
                                .opacity(0.5)
                                .padding(.leading, 26)
                        }
                        
                        TextField("", text: $guest_nickname)
                            .frame(height: 41)
                            .focused($isFocused)
                            .submitLabel(.done)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isFocused = true // 화면 뜨자마자 자동 포커스
                                }
                            }
                            .padding(.horizontal, 26)
                            .padding(.vertical, 17)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.white)
                                        .opacity(0.14)
                                    
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.brown, lineWidth: 1)
                                }
                            )
                    }
                    .padding(.bottom, 4)
                    
                    HStack {
                        Spacer()
                        
                        Text("0/10")
                            .font(.system(size: 16))
                            .foregroundColor(.brown5)
                    }
                    .padding(.top, -27)
                    .padding(.trailing, 12)
                    Spacer()
                }
                .padding(.horizontal, 20)

                if keyboard.isKeyboardVisible {
                    Button {
                        isFocused = false
                        let guestName = guest_nickname.trimmingCharacters(in: .whitespaces)
                        if !guestName.isEmpty {
                            navigationManager.path.append(.roomList(guestName))
                        }
                        
                    } label: {
                        RoundedRectangle(cornerRadius: 34)
                            .fill(Color("Brown1"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .overlay(
                                Text("입력 완료")
                                    .foregroundColor(.white1)
                                    .font(.pretendard(.semiBold, size: 20))
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    navigationManager.pop()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.brown1)
                }
            }
        }
    }
}

#Preview {
    GuestNameInputView()
}
