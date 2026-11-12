import SwiftUI

/// 화면에서 말 종류를 공통 색상 쌍으로 연결한다. DesignSystem은 게임 모델을 알지 않는다.
extension PieceType {
    var surfaceColors: SurfaceColors {
        switch self {
        case .yellow: ThemeColors.playerYellow
        case .jade: ThemeColors.playerJade
        case .blue: ThemeColors.playerBlue
        case .red: ThemeColors.playerRed
        }
    }

    var backgroundColor: Color { surfaceColors.background }
    var textColor: Color { surfaceColors.foreground }
}
