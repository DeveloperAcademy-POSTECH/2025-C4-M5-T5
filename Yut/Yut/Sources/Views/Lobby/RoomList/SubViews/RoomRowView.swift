import SwiftUI

struct RoomRowView: View {
    let room: RoomModel

    var body: some View {
        HStack {
            Text("\(room.hostName)의 윷놀이방").font(Typography.body)
            Spacer()
            Text("\(room.currentPlayers)/\(room.maxPlayers)").font(.pretendard(.medium, size: 18))
        }
        .foregroundStyle(ThemeColors.textSecondary)
        .frame(height: 82)
        .padding(.horizontal, 24)
        .surfaceStyle()
    }
}
