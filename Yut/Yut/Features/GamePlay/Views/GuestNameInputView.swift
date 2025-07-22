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
                    Text("닉네임을 입력해 주세요")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.brown1)
                    
                    // 닉네임 입력창
                    ZStack(alignment: .leading) {
                        if guest_nickname.isEmpty {
                            Text("닉네임")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.gray)
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
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.brown, lineWidth: 1)
                            )
                    }
                    
                    HStack {
                        Spacer()
                        
                        Text("0/10")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, -27)
                    .padding(.trailing, 12)
                    Spacer()
                }
                .padding(.horizontal, 20)

                
                if keyboard.isKeyboardVisible {
                    Button(action: {
                        // 닉네임 저장 후 RoomListView로 이동
                        isFocused = false
                        let guestName = guest_nickname.trimmingCharacters(in: .whitespaces)
                        if !guestName.isEmpty {
                            navigationManager.path.append(.roomList(guestName))
                        }
                        
                    }) {
                        Text("입력 완료")
                            .foregroundColor(.white)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brown)
                    }
                }
            }
        }
    }
}


#Preview {
    GuestNameInputView()
}
