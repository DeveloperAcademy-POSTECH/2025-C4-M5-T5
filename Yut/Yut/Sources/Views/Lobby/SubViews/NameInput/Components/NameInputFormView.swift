import SwiftUI

struct NameInputFormView: View {
    @Binding var nickname: String
    let title: String
    let onSubmit: () -> Void
    var autoFocus = false

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text(title)
                .font(Typography.screenTitle)
                .foregroundStyle(ThemeColors.textPrimary)
                .padding(.top, 20)
            TextInputField(text: $nickname, placeholder: "닉네임", characterLimit: 10, autoFocus: autoFocus)
            Spacer()
            ActionButton(title: "입력 완료") {
                endTextEditing()
                onSubmit()
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 20)
    }
}
