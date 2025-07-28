//
//  NameInputFormView.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/22/25.
//

import SwiftUI

struct NameInputFormView: View {
    let title: String
    @Binding var nickname: String
    let onSubmit: () -> Void
    var autoFocus: Bool = false
    
    @FocusState private var isFocused: Bool
    @StateObject private var keyboard = KeyboardObserver()
    
    var body: some View {
        VStack (spacing: 0) {
            VStack(alignment: .leading, spacing: 32) {
                Text(title)
                    .font(.pretendard(.semiBold, size: 28))
                    .foregroundColor(.brown1)
                    .padding(.top, 20)
                
                // 닉네임 입력창
                ZStack(alignment: .leading) {
                    if nickname.isEmpty {
                        Text("닉네임")
                            .font(.pretendard(.semiBold, size: 20))
                            .foregroundColor(.brown5.opacity(0.5))
                            .padding(.leading, 26)
                    }
                    
                    TextField("", text: $nickname)
                        .frame(height: 41)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 17)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.14))
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.brown, lineWidth: 1)
                            }
                        )
                        .onChange(of: nickname) { newValue in
                            if newValue.count > 10 {
                                nickname = String(newValue.prefix(10))
                            }
                        }
                }
            }
            .padding(.bottom, 12)
            
            HStack {
                Spacer()
                Text("\(nickname.count)/10")
                    .font(.system(size: 15))
                    .foregroundColor(.brown5)
            }
            .padding(.trailing, 12)
            
            Spacer()
            
//            if keyboard.isKeyboardVisible {
                Button {
                    isFocused = false
                    onSubmit()
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
                .padding(.bottom, 12)
//            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            if autoFocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                }
            }
        }
    }
}

// #Preview {
//    NameInputFormView()
// }
