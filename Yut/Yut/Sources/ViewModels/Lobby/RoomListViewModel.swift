import Combine
import Foundation

@MainActor
final class RoomListViewModel: ObservableObject {
    @Published private(set) var rooms: [RoomModel] = []

    private let session: any LobbySessionManaging
    private let navigator: any NameInputNavigating
    private var hasRequestedConnection = false

    init(session: any LobbySessionManaging, navigator: any NameInputNavigating) {
        self.session = session
        self.navigator = navigator
        session.availableRoomsPublisher.receive(on: RunLoop.main).assign(to: &$rooms)
    }

    func selectRoom(_ room: RoomModel) {
        guard !hasRequestedConnection, session.connect(to: room) else { return }
        hasRequestedConnection = true
        navigator.showWaitingRoom(room)
    }

    func goBack() {
        session.disconnect()
        navigator.goBack()
    }
}
