@MainActor
protocol GameNavigating: AnyObject {
    func showGame()
    func showWinner()
    func returnHome()
}

extension NavigationManager: GameNavigating {
    func showWinner() {
        guard path.last != .winner else { return }
        if path.last == .playView { _ = path.popLast() }
        push(.winner)
    }
}

