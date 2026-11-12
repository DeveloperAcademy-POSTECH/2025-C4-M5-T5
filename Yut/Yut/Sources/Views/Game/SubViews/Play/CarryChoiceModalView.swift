import SwiftUI

struct CarryChoiceModalView: View {
    let onSeparate: () -> Void
    let onCarry: () -> Void

    var body: some View {
        ModalPanel {
            VStack(spacing: 20) {
                Text("두 말이 한 곳에서 만났어요!\n업을까요?")
                    .font(Typography.dialogTitle)
                    .foregroundStyle(ThemeColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                HStack(spacing: 12) {
                    ActionButton(title: "따로 가기", size: .large, action: onSeparate)
                    ActionButton(title: "업기", size: .large, action: onCarry)
                }
            }
        }
    }
}
