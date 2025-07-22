//
//  UIViewButton.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/22/25.
//

import SwiftUI

struct UIViewButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            ZStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 34)
                        .fill(
                            (isEnabled ? Color("White3") : Color.gray)
//                                .opacity(0.1)
                        )
                        .blur(radius: 35)
                        .clipShape(RoundedRectangle(cornerRadius: 34))
                    
                    RoundedRectangle(cornerRadius: 34)
                        .stroke(
                            Color("Brown3").opacity(0.2),
                            lineWidth: 1
                        )
                }
                
                Text(title)
                    .foregroundColor(.brown2)
                    .font(.system(size: 22, weight: .bold, design: .default))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 75)
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    UIViewButton(
        title: "확인", // 테스트용 타이틀
        isEnabled: true, // 활성화 여부
        action: {
            print("버튼 클릭됨")
        }
    )
}
