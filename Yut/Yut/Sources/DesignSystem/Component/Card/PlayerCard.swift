import SwiftUI

/// 로비 모델 대신 표시할 이름과 이미지 이름만 받는다.
struct PlayerCard: View {
    let name: String
    let profileImage: String

    var body: some View {
        PlayerSlotCard(name: name) {
            Image(profileImage)
                .resizable()
                .scaledToFill()
        }
    }
}
