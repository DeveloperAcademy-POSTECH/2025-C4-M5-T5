import SwiftUI

/// 기존 대기실의 배치·여백·카드 격자를 두 플레이 방식이 함께 사용한다.
struct WaitingRoomLayout<Slots: View>: View {
    let title: String
    let leaveAccessibilityLabel: String
    let buttonTitle: String
    let canStart: Bool
    let onLeave: () -> Void
    let onStart: () -> Void
    let slots: Slots

    init(title: String, leaveAccessibilityLabel: String = "방 나가기", buttonTitle: String,
         canStart: Bool, onLeave: @escaping () -> Void, onStart: @escaping () -> Void,
         @ViewBuilder slots: () -> Slots) {
        self.title = title
        self.leaveAccessibilityLabel = leaveAccessibilityLabel
        self.buttonTitle = buttonTitle
        self.canStart = canStart
        self.onLeave = onLeave
        self.onStart = onStart
        self.slots = slots()
    }

    var body: some View {
        VStack {
            WaitingRoomHeader(title: title, leaveAccessibilityLabel: leaveAccessibilityLabel, onLeave: onLeave)
                .padding(.top, 30)
            Spacer()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                slots
            }
            Spacer()
            ActionButton(title: buttonTitle, isEnabled: canStart, action: onStart)
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .background(ThemeColors.canvas.ignoresSafeArea())
    }
}
