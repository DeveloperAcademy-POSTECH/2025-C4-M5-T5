//
//  EmptyPlayerCard.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/21/25.
//

import SwiftUI

struct EmptyPlayerCard: View {
    var body: some View {
        VStack {
            Circle()
                .fill(.gray)
                .frame(width: 135, height: 135)
                .padding(.top, 64)
                .padding(.bottom, 82)
        }
        .frame(
            width: UIScreen.main.bounds.width / 2 - 24,
            height: 289
        )
        .background(.white.opacity(0.35))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        )
    }
}

#Preview {
    EmptyPlayerCard()
}
