import SwiftUI

/// 글자색과 배경 밝기를 같은 테마로 적용하는 카드·AR 오버레이 공통 스타일이다.
struct SurfaceStyle: ViewModifier {
    enum Kind {
        case card
        case overlay
    }

    let kind: Kind
    let cornerRadius: CGFloat
    let colors: SurfaceColors?

    func body(content: Content) -> some View {
        content
            .foregroundStyle(colors?.foreground ?? ThemeColors.textPrimary)
            .background {
                let shape = RoundedRectangle(cornerRadius: cornerRadius)
                if let colors {
                    shape.fill(colors.background)
                } else if kind == .overlay {
                    shape.fill(.ultraThinMaterial)
                        .overlay { shape.fill(ThemeColors.surface.opacity(0.94)) }
                } else {
                    shape.fill(ThemeColors.cardSurface)
                }
            }
            .overlay { RoundedRectangle(cornerRadius: cornerRadius).stroke(ThemeColors.border, lineWidth: 1) }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: ThemeColors.shadow.opacity(kind == .overlay ? 0.16 : 0.06), radius: 12, y: 4)
    }
}

extension View {
    func surfaceStyle(_ kind: SurfaceStyle.Kind = .card, cornerRadius: CGFloat = 12, colors: SurfaceColors? = nil) -> some View {
        modifier(SurfaceStyle(kind: kind, cornerRadius: cornerRadius, colors: colors))
    }
}
