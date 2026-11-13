import SwiftUI

struct CreatorsSection: View {
    let names: [String]

    var body: some View {
        VStack(spacing: 32) {
            CreatorsHeader()

            VStack(spacing: 16) {
                Text(names.prefix(3).joined(separator: " · "))
                if names.count > 3 {
                    Text(names.dropFirst(3).joined(separator: " · "))
                }
            }
            .font(Typography.body)
        }
        .foregroundStyle(ThemeColors.textPrimary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}
