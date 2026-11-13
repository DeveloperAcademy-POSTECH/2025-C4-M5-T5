import SwiftUI

/// 원본 말 이미지의 넓은 투명 여백을 확대·클리핑해 작은 아이콘에서도 말 모양을 읽을 수 있게 한다.
struct PieceIcon: View {
    let imageName: String
    let size: CGFloat

    var body: some View {
        Image(imageName).resizable().scaledToFit()
            .frame(width: size, height: size)
            .scaleEffect(1.65)
            .frame(width: size, height: size)
            .clipped()
            .accessibilityHidden(true)
    }
}
