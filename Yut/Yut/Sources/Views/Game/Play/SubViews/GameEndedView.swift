import SwiftUI

/// 홈 전환 중 경로가 남아도 빈 화면 대신 종료 상태와 이동 수단을 제공한다.
struct GameEndedView: View {
    let onHome: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("게임이 중단되었습니다").font(Typography.screenTitle)
            Text("홈에서 새 게임을 시작할 수 있습니다.").font(Typography.body).multilineTextAlignment(.center)
            ActionButton(title: "홈으로", action: onHome)
            Spacer()
        }
        .foregroundStyle(ThemeColors.textPrimary)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ThemeColors.canvas.ignoresSafeArea())
    }
}
