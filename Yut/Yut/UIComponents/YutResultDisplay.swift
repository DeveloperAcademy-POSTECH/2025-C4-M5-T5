//
//  YutResultDisplay.swift
//  Yut
//
//  Created by soyeonsoo on 7/23/25.
//

import SwiftUI

struct YutResultDisplay: View {
    let result: YutResult?
    
    var body: some View {
        let text = result?.displayText ?? "한 번 더!"
        
        Text(text)
            .font(.hancom(.hoonmin, size: text == "한 번 더!" ? 64 : 108))
            .foregroundColor(.brown1)
            .frame(width: 300, height: 300)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .background(
                        Circle()
                            .fill(Color.white3.opacity(0.8))
                    )
            )
            .overlay(
                Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5)
            )
            .accessibilityLabel(text)
    }
}

//#Preview {
//    // YutResultDisplay(result: .geol)
//    YutResultDisplay(result: nil) // "한 번 더!"
//}
