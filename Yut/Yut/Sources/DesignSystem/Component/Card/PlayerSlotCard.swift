import SwiftUI

/// 빈 슬롯도 이름 영역을 확보해 프로필과 추가 아이콘의 중심 위치를 유지한다.
struct PlayerSlotCard<Portrait: View>: View {
    let name: String?
    @ViewBuilder let portrait: () -> Portrait

    var body: some View {
        VStack {
            portrait()
                .frame(width: 135, height: 135)
                .clipShape(Circle())
                .padding(.top, 64)
                .padding(.bottom, 25)
            Text(name ?? " ")
                .font(Typography.sectionTitle)
                .foregroundStyle(ThemeColors.textPrimary)
                .opacity(name == nil ? 0 : 1)
                .accessibilityHidden(name == nil)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 289)
        .surfaceStyle()
    }
}
