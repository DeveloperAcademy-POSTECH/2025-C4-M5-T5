import SwiftUI

/// 크기·아이콘 변화 없이 배경과 글자색으로 선택 상태를 표시한다.
struct ChoiceButton: View {
    let title: String
    let isSelected: Bool
    let isEnabled: Bool
    let colors: SurfaceColors?
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(ChoiceButtonStyle(isSelected: isSelected, colors: colors))
            .disabled(!isEnabled)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .transaction { $0.animation = nil }
    }
}

private struct ChoiceButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let isSelected: Bool
    let colors: SurfaceColors?

    private var foreground: Color {
        if isSelected { return colors?.foreground ?? ThemeColors.primaryButtonText }
        guard isEnabled else { return ThemeColors.disabledButtonText }
        return ThemeColors.secondaryButtonText
    }

    private var background: Color {
        if isSelected { return colors?.background ?? ThemeColors.primaryButtonBackground }
        guard isEnabled else { return ThemeColors.disabledButtonBackground }
        return ThemeColors.secondaryButtonBackground
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.button)
            .foregroundStyle(foreground)
            .padding(.horizontal, 16)
            .frame(minWidth: 64, minHeight: 44)
            .background(background, in: RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.border, lineWidth: 1) }
            .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}
