import SwiftUI

struct SettingsMenuRow: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol).frame(width: 26)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right").font(Typography.caption)
            }
            .font(Typography.body)
            .foregroundStyle(ThemeColors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
