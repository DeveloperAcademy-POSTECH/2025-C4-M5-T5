@MainActor
protocol WaitingRoomNavigating: AnyObject {
    func showGame()
    func returnHome()
}

extension NavigationManager: WaitingRoomNavigating {
    func showGame() {
        guard path.last != .playView else { return }
        if path.last == .winner { _ = path.popLast() }
        push(.playView)
    }
    func returnHome() { popToRoot() }
}

