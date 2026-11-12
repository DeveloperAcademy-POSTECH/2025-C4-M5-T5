import SwiftUI

struct WinnerPieceView: View {
    let pieceType: PieceType
    
    @State private var floatUp = false
    
    var body: some View {
        Image(pieceType.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 390)
            .offset(y: floatUp ? -10 : 28)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: floatUp
            )
            .shadow(color: .white.opacity(0.8), radius: 50, x: 0, y: 0)
            .onAppear{
                floatUp = true
            }
    }
}
