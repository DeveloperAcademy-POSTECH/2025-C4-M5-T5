import SwiftUI

/// 카드·안내·결과 표시가 함께 사용하는 배경과 글자색 쌍이다.
struct SurfaceColors {
    let background: Color
    let foreground: Color
}

/// 원본 색상 에셋의 밝기 전환을 역할별 배경·전경 쌍으로 사용한다.
/// 다크모드에서는 강조 배경이 밝아지므로 그 위 글자도 어두운 canvas 색으로 함께 전환한다.
enum ThemeColors {
    static let canvas = Color.white1
    static let textPrimary = Color.brown1
    static let textSecondary = Color.brown5
    static let placeholder = Color.brown5.opacity(0.7)
    static let fieldBorder = Color.brown5.opacity(0.6)
    static let surface = Color.white3
    static let cardSurface = Color.white2.opacity(0.45)
    static let border = Color.brown5.opacity(0.2)
    static let primaryButtonBackground = Color.brown4
    static let primaryButtonText = Color.white1
    static let secondaryButtonBackground = Color.white3
    static let secondaryButtonText = Color.brown2
    static let disabledButtonBackground = Color.white2
    static let disabledButtonText = Color.brown5
    static let progressFill = Color.white2
    static let scrim = Color.black.opacity(0.4)
    static let shadow = Color.black

    // 말 색상은 두 모드에서 고정이므로 승자 제목도 고정 대비색을 사용한다.
    static let onLightPlayerColor = Color(red: 0x33 / 255.0, green: 0x1A / 255.0, blue: 0x0D / 255.0)
    static let onDarkPlayerColor = Color.white

    static let playerYellow = SurfaceColors(background: Color("piece_yellow"), foreground: onLightPlayerColor)
    static let playerJade = SurfaceColors(background: Color("piece_jade"), foreground: onLightPlayerColor)
    static let playerBlue = SurfaceColors(background: Color("piece_blue"), foreground: onDarkPlayerColor)
    static let playerRed = SurfaceColors(background: Color("piece_red"), foreground: onLightPlayerColor)
}
