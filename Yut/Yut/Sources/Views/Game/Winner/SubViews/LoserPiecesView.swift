import SwiftUI

struct LoserPiecesView: View {
    let excluding: PieceType
    
    var body: some View {
        let losers = PieceType.allCases.filter { $0 != excluding }
        ZStack {
            ForEach(Array(losers.enumerated()), id: \.element) { index, piece in
                Image(piece.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 182)
                    .rotationEffect(.degrees(rotation(for: index)))
                    .offset(offset(for: index))
            }
        }
    }
    
    private func rotation(for index: Int) -> Double {
        [18, -3, -20][index]
    }
    
    private func offset(for index: Int) -> CGSize {
        [CGSize(width: -88, height: -90),
         CGSize(width: 0, height: -40),
         CGSize(width: 96, height: -80)][index]
    }
}
