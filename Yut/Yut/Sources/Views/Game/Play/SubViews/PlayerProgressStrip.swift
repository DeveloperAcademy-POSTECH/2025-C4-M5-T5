import SwiftUI

struct PlayerProgressStrip: View {
    @ScaledMetric(relativeTo: .body) private var stripHeight: CGFloat = 144
    let players: [PlayerPieceProgress]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(players) { player in
                        PlayerProgressCard(progress: player).id(player.id)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                if let id = players.first(where: \.isCurrent)?.id { proxy.scrollTo(id, anchor: .center) }
            }
            .onChange(of: players.first(where: \.isCurrent)?.id) { _, id in
                if let id { proxy.scrollTo(id, anchor: .center) }
            }
        }
        .frame(height: stripHeight)
        .accessibilityIdentifier("playerPieceProgress")
    }
}

private struct PlayerProgressCard: View {
    let progress: PlayerPieceProgress

    var body: some View {
        let colors = PieceType.from(sequence: progress.order + 1)?.surfaceColors ?? ThemeColors.playerYellow
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let type = PieceType.from(sequence: progress.order + 1) {
                    PieceIcon(imageName: type.imageName, size: 40)
                }
                Text(progress.name).lineLimit(1)
            }
            .font(Typography.caption)
            .fontWeight(progress.isCurrent ? .bold : .regular)
            HStack(alignment: .top, spacing: 8) {
                PieceProgressCount(title: "대기 중인 말", count: progress.waitingNumbers.count,
                    total: progress.positions.count, colors: colors)
                PieceProgressCount(title: "완주한 말", count: progress.finishedNumbers.count,
                    total: progress.positions.count, colors: colors)
            }
        }
        .padding(10)
        .frame(width: 242)
        .surfaceStyle(.overlay, colors: colors, showsShadow: false)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(progress.name)의 말 상태")
    }
}

private struct PieceProgressCount: View {
    let title: String
    let count: Int
    let total: Int
    let colors: SurfaceColors

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
            CountIndicator(count: count, total: total,
                colors: SurfaceColors(background: colors.foreground, foreground: colors.background),
                inactiveColor: colors.foreground.opacity(0.25))
            Text("\(count)개").font(Typography.body).monospacedDigit()
        }
        .font(Typography.caption)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) \(count)개")
    }
}
