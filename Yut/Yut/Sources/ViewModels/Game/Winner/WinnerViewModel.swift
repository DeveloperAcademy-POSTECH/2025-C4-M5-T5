import Combine

@MainActor
final class WinnerViewModel: ObservableObject {
    private let game: GameSessionController
    var winnerName: String { game.state?.winner?.name ?? "플레이어" }
    var winnerPieceType: PieceType { PieceType.from(sequence: (game.state?.winner?.order ?? 0) + 1) ?? .yellow }

    init(game: GameSessionController) { self.game = game }
    func finishGame() { game.transport.disconnect() }
    func playAgain() { game.requestRematch() }
}
