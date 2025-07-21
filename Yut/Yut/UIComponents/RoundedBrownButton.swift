//
//  RoundedBrownButton.swift
//  Yut
//
//  Created by yunsly on 7/17/25.
//

import SwiftUI
//
//struct RoundedBrownButton: View {
//    let title: String
//    let isEnabled: Bool
//    let action: () -> Void
//
//    var body: some View {
//        Button(action: {
//            if isEnabled {
//                action()
//            }
//        }) {
//            ZStack {
//
//                RoundedRectangle(cornerRadius: 34)
//                    .fill(
//                        (isEnabled ? Color("Brown3") : Color.gray)
//                            .opacity(0.05)
//                    )
//                    .blur(radius: 12.5)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 34)
//                            .stroke(
//                                Color("Brown3").opacity(0.2),
//                                lineWidth: 1
//                            )
//                    )
//                Text(title)
//                    .foregroundColor(.brown2)
//                    .font(.system(size: 22, weight: .bold, design: .default))
//            }
//            .frame(maxWidth: .infinity)
//            .frame(height: 75)
//        }
//        .disabled(!isEnabled)
//    }
//}

struct RoundedBrownButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            Text(title)
                .foregroundColor(.white)
                .font(.headline)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(isEnabled ? Color(red: 56/255, green: 40/255, blue: 33/255) : Color.gray)
                .cornerRadius(24)
        }
        .padding(.horizontal, 30)
        .disabled(!isEnabled)
    }
}
