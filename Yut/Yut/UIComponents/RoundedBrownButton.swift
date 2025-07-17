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
            Text(title)
                .foregroundColor(.brown2)
                .font(.system(size: 22, weight: .bold, design: .default))
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .frame(height: 75)
                .background(isEnabled ? Color("white2") : Color.gray)
                .cornerRadius(34)
        }
        .disabled(!isEnabled)
    }
}
