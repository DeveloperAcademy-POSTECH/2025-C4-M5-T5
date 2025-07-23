//
//  ProgressBar.swift
//  Yut
//
//  Created by soyeonsoo on 7/23/25.
//

import SwiftUI

struct ProgressBar: View {
    let text: String
    let currentProgress: Float
    let minRequiredArea: Float
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial.opacity(0.8))

            GeometryReader { geometry in
                let width = CGFloat(currentProgress / minRequiredArea) * geometry.size.width
                RoundedRectangle(cornerRadius: 28)
                    .fill(.white3)
                    .frame(width: width)
            }

            Text(text)
                .font(.system(size: 20))
                .fontWeight(.medium)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 72)
        .cornerRadius(28)
        .padding(.horizontal, 16)
    }
}

#Preview {
    ProgressBar(
        text: "바닥을 충분히 색칠해주세요",
        currentProgress: 8,
        minRequiredArea: 15
    )
}
