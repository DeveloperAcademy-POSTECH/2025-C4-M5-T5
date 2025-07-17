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
