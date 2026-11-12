import SwiftUI

struct SettingsMenuSection: View {
    let onTerms: () -> Void
    let onPrivacyPolicy: () -> Void
    let onSupport: () -> Void
    let onCreators: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SettingsMenuRow(title: "이용약관", symbol: "doc.text", action: onTerms)
            Divider().overlay(ThemeColors.border)
            SettingsMenuRow(title: "개인정보처리방침", symbol: "hand.raised", action: onPrivacyPolicy)
            Divider().overlay(ThemeColors.border)
            SettingsMenuRow(title: "문의하기", symbol: "envelope", action: onSupport)
            Divider().overlay(ThemeColors.border)
            SettingsMenuRow(title: "제작자", symbol: "person.2", action: onCreators)
        }
        .padding(.horizontal, 20)
        .surfaceStyle(cornerRadius: 20)
    }
}
