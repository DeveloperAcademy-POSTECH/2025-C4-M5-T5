import Combine
import Foundation

@MainActor
final class HostNameInputViewModel: ObservableObject {
    @Published var nickname = ""

    private let session: any LobbySessionManaging
    private let navigator: any NameInputNavigating

    init(session: any LobbySessionManaging, navigator: any NameInputNavigating) {
        self.session = session
        self.navigator = navigator
    }

    func submitNickname() {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let room = session.hostRoom(named: name) else { return }
        navigator.showWaitingRoom(room)
    }

    func goBack() { navigator.goBack() }
}
