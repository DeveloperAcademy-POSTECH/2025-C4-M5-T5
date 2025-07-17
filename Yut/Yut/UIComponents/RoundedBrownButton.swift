//
//  RoundedBrownButton.swift
//  Yut
//
//  Created by yunsly on 7/17/25.
//

import SwiftUI

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
<<<<<<< HEAD
            ZStack {

                RoundedRectangle(cornerRadius: 34)
                    .fill(
                        (isEnabled ? Color("white2") : Color.gray)
                            .opacity(0.05)
                    )
                    .blur(radius: 12.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 34)
                            .stroke(
                                Color("white2").opacity(0.2),
                                lineWidth: 1
                            )
                    )
                Text(title)
                    .foregroundColor(.brown2)
                    .font(.system(size: 22, weight: .bold, design: .default))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 75)
=======
            Text(title)
                .foregroundColor(.brown2)
                .font(.system(size: 22, weight: .bold, design: .default))
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .frame(height: 75)
                .background(isEnabled ? Color("white2") : Color.gray)
                .cornerRadius(34)
>>>>>>> origin/feat/home-view-27
        }
        .disabled(!isEnabled)
    }
}
