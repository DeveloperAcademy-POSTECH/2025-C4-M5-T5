import SwiftUI

/// 로비 모델 대신 표시할 이름과 이미지 이름만 받는다.
struct PlayerCard: View {
    let name: String
    let profileImage: String

    var body: some View {
        VStack {
            Image(profileImage)
                .resizable()
                .scaledToFill()
                .frame(width: 135, height: 135)
                .clipShape(Circle())
                .padding(.top, 64)
                .padding(.bottom, 25)
            Text(name)
                .font(Typography.sectionTitle)
                .foregroundStyle(ThemeColors.textPrimary)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 289)
        .surfaceStyle()
    }
}
