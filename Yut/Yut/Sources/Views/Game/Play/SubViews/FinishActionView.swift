import SwiftUI

/// 완주 가능한 동안에만 출발점의 화면 좌표를 추적한다. 3D 충돌면이나 물리 설정은 추가하지 않는다.
struct FinishActionView: View {
    let colors: SurfaceColors?
    let position: () -> CGPoint?
    let onFinish: () -> Void

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { _ in
                if let point = position() {
                    ActionButton(title: "완주하기", size: .compact, cornerRadius: 25, colors: colors, action: onFinish)
                        .frame(width: 120)
                        .position(x: min(max(point.x, 76), geometry.size.width - 76),
                                  y: min(max(point.y + 40, 260), geometry.size.height - 160))
                        .accessibilityIdentifier("finishPiece")
                }
            }
        }
    }
}
