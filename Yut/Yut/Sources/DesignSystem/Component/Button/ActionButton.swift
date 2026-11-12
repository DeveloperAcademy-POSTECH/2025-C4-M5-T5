import SwiftUI

/// 버튼의 배경·글자·비활성 색을 함께 적용해 화면별 색상 조합이 어긋나지 않게 한다.
struct ActionButton: View {
    enum Variant {
        case primary
        case secondary
    }

    enum Size {
        case compact
        case regular
        case large

        var height: CGFloat {
            switch self {
            case .compact: 50
            case .regular: 64
            case .large: 70
            }
        }
    }

    let title: String
    var isEnabled = true
    var variant: Variant = .primary
    var size: Size = .regular
    var cornerRadius: CGFloat = 34
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(ActionButtonStyle(variant: variant, height: size.height, cornerRadius: cornerRadius))
            .disabled(!isEnabled)
    }
}

private struct ActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let variant: ActionButton.Variant
    let height: CGFloat
    let cornerRadius: CGFloat

    private var foreground: Color {
        guard isEnabled else { return ThemeColors.disabledButtonText }
        return variant == .primary ? ThemeColors.primaryButtonText : ThemeColors.secondaryButtonText
    }

    private var background: Color {
        guard isEnabled else { return ThemeColors.disabledButtonBackground }
        return variant == .primary ? ThemeColors.primaryButtonBackground : ThemeColors.secondaryButtonBackground
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.button)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(background, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                if variant == .secondary {
                    RoundedRectangle(cornerRadius: cornerRadius).stroke(ThemeColors.border, lineWidth: 1)
                }
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
