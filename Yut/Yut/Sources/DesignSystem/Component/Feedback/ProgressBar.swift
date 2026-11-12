import SwiftUI

struct ProgressBar: View {
    let text: String
    let currentProgress: Float
    let minRequiredArea: Float
    var colors: SurfaceColors? = nil

    private var fraction: CGFloat {
        guard currentProgress.isFinite, minRequiredArea.isFinite, minRequiredArea > 0 else { return 0 }
        return CGFloat(min(max(currentProgress / minRequiredArea, 0), 1))
    }

    var body: some View {
        ZStack(alignment: .leading) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle().fill(colors?.background ?? ThemeColors.progressFill)
                    Text(text)
                        .font(Typography.instruction)
                        .foregroundStyle(colors?.foreground ?? ThemeColors.textPrimary)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .accessibilityHidden(true)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
                .mask(alignment: .leading) { Rectangle().frame(width: fraction * geometry.size.width) }
            }
            .zIndex(1)
            Text(text)
                .font(Typography.instruction)
                .foregroundStyle(ThemeColors.textPrimary)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 72)
        .surfaceStyle(.overlay)
        .padding(.horizontal, 20)
    }
}
