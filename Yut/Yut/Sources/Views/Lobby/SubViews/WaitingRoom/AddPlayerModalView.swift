import SwiftUI

struct AddPlayerModalView: View {
    @Binding var isPresented: Bool
    @Binding var nickname: String
    let onSubmit: () -> Void

    var body: some View {
        ModalPanel(onDismiss: { isPresented = false }) {
            VStack(spacing: 20) {
                Text("닉네임을 입력하세요")
                    .font(Typography.dialogTitle)
                    .foregroundStyle(ThemeColors.textPrimary)
                TextInputField(text: $nickname, placeholder: "닉네임", characterLimit: 10, size: .compact)
                ActionButton(title: "추가", isEnabled: !nickname.isEmpty, size: .compact, cornerRadius: 25) {
                    onSubmit()
                    isPresented = false
                    nickname = ""
                }
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: isPresented)
    }
}
