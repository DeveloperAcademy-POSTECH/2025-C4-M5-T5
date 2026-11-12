import SwiftUI

struct InstructionView: View {
    let text: String
    var colors: SurfaceColors? = nil

    var body: some View {
        Text(text)
            .font(Typography.instruction)
            .foregroundStyle(colors?.foreground ?? ThemeColors.textPrimary)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .surfaceStyle(.overlay, colors: colors)
            .padding(.horizontal, 20)
    }
}
