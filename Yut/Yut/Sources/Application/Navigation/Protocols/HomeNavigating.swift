@MainActor
protocol HomeNavigating: AnyObject {
    func showLocalPlay()
    func showHostNameInput()
    func showGuestNameInput()
    func showSettings()
}

extension NavigationManager: HomeNavigating {
    func showLocalPlay() { push(.localPlay) }
    func showHostNameInput() { push(.hostNameInput) }
    func showGuestNameInput() { push(.guestNameInput) }
    func showSettings() { push(.settings) }
}
