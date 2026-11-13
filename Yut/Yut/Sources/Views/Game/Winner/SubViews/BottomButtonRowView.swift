import SwiftUI

struct BottomButtonRowView: View {
    let onFinish: () -> Void
    let onPlayAgain: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            ActionButton(title: "끝내기", size: .large, action: onFinish)
            ActionButton(title: "한 판 더!", size: .large, action: onPlayAgain)
        }
        .padding(.horizontal, 20)
        .frame(height: 70)
    }
}
