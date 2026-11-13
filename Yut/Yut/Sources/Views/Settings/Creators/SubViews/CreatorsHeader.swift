import SwiftUI

struct CreatorsHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("제작자")
                .font(Typography.screenTitle)
                .foregroundStyle(ThemeColors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("CREATED BY")
                .font(Typography.caption)
                .tracking(2)
                .foregroundStyle(ThemeColors.textSecondary.opacity(0.8))
        }
    }
}
