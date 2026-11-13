import SwiftUI

struct CountIndicator: View {
    let count: Int
    let total: Int
    let colors: SurfaceColors
    var inactiveColor: Color? = nil

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<max(total, 0), id: \.self) { index in
                Circle()
                    .fill(index < count ? colors.background : (inactiveColor ?? ThemeColors.border))
                    .overlay {
                        Circle().stroke(index < count ? colors.foreground.opacity(0.4) : (inactiveColor ?? ThemeColors.fieldBorder), lineWidth: 1)
                    }
                    .frame(width: 16, height: 16)
            }
        }
        .accessibilityHidden(true)
    }
}
