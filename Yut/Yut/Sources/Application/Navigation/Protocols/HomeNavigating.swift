@MainActor
protocol HomeNavigating: AnyObject {
    func showHostNameInput()
    func showGuestNameInput()
    func showSettings()
}

extension NavigationManager: HomeNavigating {
    func showHostNameInput() { push(.hostNameInput) }
    func showGuestNameInput() { push(.guestNameInput) }
    func showSettings() { push(.settings) }
}
