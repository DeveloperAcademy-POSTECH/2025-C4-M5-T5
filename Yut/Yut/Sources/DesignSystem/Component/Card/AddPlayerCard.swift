import SwiftUI

struct AddPlayerCard: View {
    var systemImage = "plus"
    var body: some View {
        PlayerSlotCard(name: nil) {
            ZStack {
                Circle().fill(ThemeColors.surface).frame(width: 135, height: 135)
                Image(systemName: systemImage)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
            }
        }
    }
}
