import SwiftUI

struct WaitingRoomHeader: View {
    let title: String
    var leaveAccessibilityLabel = "방 나가기"
    let onLeave: () -> Void

    var body: some View {
        HStack {
            Color.clear.frame(width: 44, height: 44).accessibilityHidden(true)
            Text(title)
                .font(Typography.sectionTitle)
                .foregroundStyle(ThemeColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
            IconButton(systemName: "xmark", accessibilityLabel: leaveAccessibilityLabel, action: onLeave)
        }
    }
}
