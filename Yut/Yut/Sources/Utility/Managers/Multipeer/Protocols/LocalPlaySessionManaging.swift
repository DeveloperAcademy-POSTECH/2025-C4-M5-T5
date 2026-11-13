@MainActor
protocol LocalPlaySessionManaging: AnyObject {
    func startLocalGame(slots: Set<Int>) -> Bool
}

extension MPCManager: LocalPlaySessionManaging {}
