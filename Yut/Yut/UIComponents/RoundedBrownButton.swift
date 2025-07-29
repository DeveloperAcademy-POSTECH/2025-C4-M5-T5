import SwiftUI

struct RoundedBrownButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            Text(title)
                .foregroundColor(.white)
                .font(.headline)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(
                    isEnabled
                    ? Color.brown1.opacity(0.8)
                    : Color.gray
                )
                .cornerRadius(24)
        }
        .padding(.horizontal, 20)
        .disabled(!isEnabled)
    }
}
