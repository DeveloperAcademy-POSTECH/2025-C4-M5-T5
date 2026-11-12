import SwiftUI

/// 화면 전환과 분리된 앱 최상단 안내다. 시스템 모달이 닫히는 중 다른 모달을 띄우지 않는다.
struct AppNoticeView: View {
    let title: String
    let message: String
    let primaryTitle: String
    let onPrimary: () -> Void
    var secondaryTitle: String? = nil
    var onSecondary: (() -> Void)? = nil

    var body: some View {
        ModalPanel {
            VStack(spacing: 20) {
                Text(title).font(Typography.dialogTitle).accessibilityAddTraits(.isHeader)
                Text(message).font(Typography.body).multilineTextAlignment(.center)
                ActionButton(title: primaryTitle, size: .compact, action: onPrimary)
                if let secondaryTitle, let onSecondary {
                    ActionButton(title: secondaryTitle, variant: .secondary, size: .compact, action: onSecondary)
                }
            }
            .foregroundStyle(ThemeColors.textPrimary)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("AppNotice")
        }
    }
}
