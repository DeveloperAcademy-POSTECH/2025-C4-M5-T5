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
            .padding(.vertical, 12)
            .padding(.horizontal,)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(.ultraThinMaterial.opacity(0.8))
            .cornerRadius(28)
            .padding(.horizontal, 16)
    }
}
