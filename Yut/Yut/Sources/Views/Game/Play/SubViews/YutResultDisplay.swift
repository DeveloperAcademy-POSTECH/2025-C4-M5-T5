//
//  YutResultDisplay.swift
//  YUT
//
//  Created by soyeonsoo on 7/23/25.
//

import SwiftUI

struct YutResultDisplay: View {
    let result: YutResult?
    var colors: SurfaceColors? = nil
    
    var body: some View {
        let text = result?.displayText ?? "한 번 더!"
        
        Text(text)
            .font(.hancom(.hoonmin, size: text == "한 번 더!" ? 64 : 108))
            .foregroundStyle(colors?.foreground ?? ThemeColors.textPrimary)
            .frame(width: 300, height: 300)
            .surfaceStyle(.overlay, cornerRadius: 150, colors: colors)
            .accessibilityLabel(text)
    }
}

//#Preview {
//    // YutResultDisplay(result: .geol)
//    YutResultDisplay(result: nil) // "한 번 더!"
//}
