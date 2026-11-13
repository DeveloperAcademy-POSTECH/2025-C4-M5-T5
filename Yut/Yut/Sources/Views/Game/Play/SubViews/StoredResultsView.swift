import SwiftUI

/// 결과는 보유 현황만 표시한다. 실제 소비는 말의 목적지를 선택할 때 결정한다.
struct StoredResultsView: View {
    let results: [StoredYutResult]
    let colors: SurfaceColors

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, value in
                    Text(value.result.displayText)
                        .font(Typography.button)
                        .padding(.horizontal, 16)
                        .frame(minWidth: 64, minHeight: 44)
                        .surfaceStyle(.card, colors: colors, showsShadow: false)
                        .accessibilityLabel("보유 결과 \(index + 1), \(value.result.displayText)")
                }
            }
        }
        .scrollIndicators(.hidden)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("storedResults")
    }
}
