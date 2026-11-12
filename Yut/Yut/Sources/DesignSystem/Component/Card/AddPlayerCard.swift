import SwiftUI

struct AddPlayerCard: View {
    var body: some View {
        VStack {
            ZStack {
                Circle().fill(ThemeColors.surface).frame(width: 135, height: 135)
                Image(systemName: "plus")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
            }
            .padding(.top, 36)
            .padding(.bottom, 25)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 289)
        .surfaceStyle()
    }
}
