import SwiftUI

/// 입력 문자·힌트·글자 수의 색과 표시 방식을 함께 관리한다.
struct TextInputField: View {
    enum Size {
        case regular
        case compact
    }

    @Binding var text: String
    @FocusState private var isFocused: Bool
    let placeholder: String
    let characterLimit: Int
    var size: Size = .regular
    var autoFocus = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(ThemeColors.placeholder))
                .font(Typography.body)
                .foregroundStyle(ThemeColors.textPrimary)
                .tint(ThemeColors.textPrimary)
                .focused($isFocused)
                .submitLabel(.done)
                .padding(.horizontal, 24)
                .frame(height: size == .regular ? 75 : 54)
                .background(ThemeColors.canvas.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.fieldBorder, lineWidth: 1) }
                .accessibilityLabel(placeholder)
                .onChange(of: text) { _, value in
                    if value.count > characterLimit { text = String(value.prefix(characterLimit)) }
                }
            Text("\(text.count)/\(characterLimit)")
                .font(Typography.caption)
                .foregroundStyle(ThemeColors.textSecondary)
                .padding(.trailing, 12)
        }
        .task {
            guard autoFocus else { return }
            do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
            guard !Task.isCancelled else { return }
            isFocused = true
        }
    }
}
