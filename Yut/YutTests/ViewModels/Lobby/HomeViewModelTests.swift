import Testing
@testable import Yut

@MainActor
struct HomeViewModelTests {
    @Test
    func homeRoutesOnlyAfterInputAndKeepsHostAndGuestFlowsDistinct() {
        let navigation = RecordingHomeNavigation()
        let viewModel = HomeViewModel(navigator: navigation)
        #expect(navigation.destinations.isEmpty)
        viewModel.createRoom()
        #expect(navigation.destinations == [.hostNameInput])
        viewModel.joinRoom()
        #expect(navigation.destinations == [.hostNameInput, .guestNameInput])
        viewModel.showSettings()
        #expect(navigation.destinations.last == .settings)
    }
}

@MainActor
private final class RecordingHomeNavigation: HomeNavigating {
    enum Destination {
        case hostNameInput
        case guestNameInput
        case settings
    }

    var destinations: [Destination] = []
    func showHostNameInput() { destinations.append(.hostNameInput) }
    func showGuestNameInput() { destinations.append(.guestNameInput) }
    func showSettings() { destinations.append(.settings) }
}
