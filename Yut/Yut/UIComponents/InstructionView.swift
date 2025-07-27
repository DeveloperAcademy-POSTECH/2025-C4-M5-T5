//
//  InstructionView.swift
//  Yut
//
//  Created by yunsly on 7/17/25.
//

import SwiftUI

struct InstructionView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 20))
            .fontWeight(.medium)
            .foregroundColor(.black)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(.ultraThinMaterial.opacity(0.6))
            .background(.white.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white, lineWidth: 2)
            )
            .cornerRadius(12)
            .padding(.horizontal, 20)
    }
}
