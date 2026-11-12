import Combine
import Foundation

@MainActor
final class GuestNameInputViewModel: ObservableObject {
    @Published var nickname = ""

    private let session: any LobbySessionManaging
    private let navigator: any NameInputNavigating

    init(session: any LobbySessionManaging, navigator: any NameInputNavigating) {
        self.session = session
        self.navigator = navigator
    }

    func submitNickname() {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        session.browseRooms(as: name)
        navigator.showRoomList(as: name)
    }

    func goBack() { navigator.goBack() }
}
