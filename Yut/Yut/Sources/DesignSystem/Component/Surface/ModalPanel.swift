import SwiftUI

/// 내용과 결정 액션은 화면이 소유하고 모달 배경·여백·표면만 공유한다.
struct ModalPanel<Content: View>: View {
    private let onDismiss: (() -> Void)?
    private let content: Content

    init(onDismiss: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.onDismiss = onDismiss
        self.content = content()
    }

    var body: some View {
        ZStack {
            ThemeColors.scrim
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onDismiss?() }
                .accessibilityHidden(true)
            content
                .padding(24)
                .frame(maxWidth: 440)
                .surfaceStyle(.overlay, cornerRadius: 24)
                .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
