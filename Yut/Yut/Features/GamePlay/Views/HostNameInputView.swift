//
//  HostNameInputView.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/17/25.
//

import SwiftUI

struct HostNameInputView: View {
    @State private var nickname: String = ""
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
//                        .foregroundColor(.brown1)
                    
                    // 닉네임 입력창
                    ZStack(alignment: .leading) {
                        if nickname.isEmpty {
                            Text("닉네임")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.leading, 26)
                        }
                        
                        TextField("", text: $nickname)
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
                        isFocused = false // 키보드 닫기
                        // 버튼 클릭시 Action
                        
                        // 새로운 Room 생성
                        let newRoom = Room(
                            name: nickname,              // 입력된 닉네임으로 방 이름 설정
                            currentPlayers: 1,           // 본인 포함 1명
                            maxPlayers: 4                // 최대 인원
                        )

                        // WaitingRoomView로 이동
                        navigationManager.path.append(.waitingRoom(newRoom))
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

struct FormState {
    var nickname: String = ""
}

#Preview {
    HostNameInputView()
}
