import Combine
import Foundation
import MultipeerConnectivity
import Testing
@testable import Yut

@MainActor
struct LobbyViewModelTests {
    private enum WaitError: Error { case timeout }

    @Test
    func clearedQueuedRoomErrorCannotCloseTheNewLobby() async throws {
        let session = FakeLobbySession()
        let navigation = RecordingLobbyNavigation()
        let viewModel = WaitingRoomViewModel(session: session, navigator: navigation)
        session.errors.send("이전 연결 오류")
        session.closed.send("이전 방 종료")
        session.closed.send(nil)
        session.errors.send(nil)
        try await Task.sleep(for: .milliseconds(100))
        #expect(viewModel.errorMessage == nil)
        #expect(navigation.homeCount == 0)
    }

    @Test
    func nicknamesAreValidatedAndGuestOpensRoomListWithoutAutoJoining() {
        let session = FakeLobbySession()
        let navigation = RecordingLobbyNavigation()
        let host = HostNameInputViewModel(session: session, navigator: navigation)
        host.nickname = " \n "
        host.submitNickname()
        #expect(session.hostedNames.isEmpty)
        host.nickname = " Host \n"
        host.submitNickname()
        #expect(session.hostedNames == ["Host"])
        #expect(navigation.waitingRooms.count == 1)

        let guest = GuestNameInputViewModel(session: session, navigator: navigation)
        guest.nickname = " Guest \n"
        guest.submitNickname()
        #expect(session.browsedNames == ["Guest"])
        #expect(navigation.roomListNames == ["Guest"])
        #expect(session.selectedRooms.isEmpty)
    }

    @Test
    func roomSelectionNavigatesOnlyAfterConnectionRequestIsAccepted() async throws {
        let session = FakeLobbySession()
        let navigation = RecordingLobbyNavigation()
        let viewModel = RoomListViewModel(session: session, navigator: navigation)
        let room = RoomModel(roomName: "Host", hostName: "Host")
        session.rooms.send([room])
        try await waitUntil { viewModel.rooms.count == 1 }
        session.canConnect = false
        viewModel.selectRoom(room)
        #expect(navigation.waitingRooms.isEmpty)
        session.canConnect = true
        viewModel.selectRoom(room)
        viewModel.selectRoom(room)
        #expect(navigation.waitingRooms == [room])
        viewModel.goBack()
        #expect(session.disconnectCount == 1)
        #expect(navigation.backCount == 1)
    }

    @Test
    func hostWaitsForStartConfirmationAndDuplicateSignalsNavigateOnce() async throws {
        let session = FakeLobbySession()
        let navigation = RecordingLobbyNavigation()
        let viewModel = WaitingRoomViewModel(session: session, navigator: navigation)
        viewModel.startGame()
        #expect(session.startCount == 0)
        session.roster.send(players())
        try await waitUntil { viewModel.canStartGame }
        session.shouldFailStart = true
        viewModel.startGame()
        #expect(navigation.gameCount == 0)
        session.shouldFailStart = false
        viewModel.startGame()
        session.started.send(true)
        try await waitUntil { navigation.gameCount == 1 }
        viewModel.startGame()
        #expect(session.startCount == 2)
        #expect(!viewModel.canStartGame)
    }

    @Test
    func guestCannotStartAndWaitsForHostRosterWhenAddingPlayer() async throws {
        let session = FakeLobbySession()
        session.isHost = false
        let navigation = RecordingLobbyNavigation()
        let viewModel = WaitingRoomViewModel(session: session, navigator: navigation)
        session.roster.send(players())
        try await waitUntil { viewModel.players.count == 2 }
        viewModel.startGame()
        #expect(session.startCount == 0)
        viewModel.addPlayer(named: " Friend \n")
        #expect(session.requestedNames == ["Friend"])
        #expect(viewModel.players.count == 2)
        session.started.send(true)
        try await waitUntil { navigation.gameCount == 1 }
    }

    @Test
    func roomClosureReturnsHomeAndNewRoomCanStartAgain() async throws {
        let session = FakeLobbySession()
        let navigation = RecordingLobbyNavigation()
        let viewModel = WaitingRoomViewModel(session: session, navigator: navigation)
        session.roster.send(players())
        session.started.send(true)
        try await waitUntil { navigation.gameCount == 1 }
        session.closed.send("방장 연결 종료")
        try await waitUntil { navigation.homeCount == 1 }
        #expect(viewModel.errorMessage == "방장 연결 종료")
        viewModel.dismissError()
        #expect(session.roomClosedReason == nil)
        #expect(session.connectionError == nil)
        try await Task.sleep(for: .milliseconds(30))
        #expect(viewModel.errorMessage == nil)
        viewModel.leaveRoom()
        #expect(viewModel.errorMessage == nil)
        session.roster.send(players())
        try await waitUntil { viewModel.canStartGame }
        viewModel.startGame()
        try await waitUntil { navigation.gameCount == 2 }
    }

    @Test
    func stoppedGameReturnsHomeWithoutWaitingForRoomClosedMessage() async throws {
        let session = FakeLobbySession()
        let navigation = RecordingLobbyNavigation()
        let viewModel = WaitingRoomViewModel(session: session, navigator: navigation)
        session.roster.send(players())
        session.started.send(true)
        try await waitUntil { navigation.gameCount == 1 }

        session.disconnect()

        try await waitUntil { navigation.homeCount == 1 }
        #expect(viewModel.players.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    private func players() -> [PlayerModel] {
        let peer = MCPeerID(displayName: "Host")
        return [PlayerModel(name: "Host", sequence: 1, peerID: peer, isHost: true),
                PlayerModel(name: "Friend", sequence: 2, peerID: peer)]
    }

    private func waitUntil(_ predicate: () -> Bool) async throws {
        for _ in 0..<100 {
            if predicate() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        throw WaitError.timeout
    }
}

@MainActor
private final class FakeLobbySession: LobbySessionManaging, WaitingRoomSessionManaging {
    let rooms = CurrentValueSubject<[RoomModel], Never>([])
    let roster = CurrentValueSubject<[PlayerModel], Never>([])
    let started = CurrentValueSubject<Bool, Never>(false)
    let closed = CurrentValueSubject<String?, Never>(nil)
    let errors = CurrentValueSubject<String?, Never>(nil)
    var isHost = true
    var hasStartedGame: Bool { started.value }
    var roomClosedReason: String? { closed.value }
    var connectionError: String? { errors.value }
    var canConnect = true
    var shouldFailStart = false
    var hostedNames: [String] = []
    var browsedNames: [String] = []
    var selectedRooms: [RoomModel] = []
    var requestedNames: [String] = []
    var startCount = 0
    var disconnectCount = 0

    var availableRoomsPublisher: AnyPublisher<[RoomModel], Never> { rooms.eraseToAnyPublisher() }
    var playersPublisher: AnyPublisher<[PlayerModel], Never> { roster.eraseToAnyPublisher() }
    var gameStartedPublisher: AnyPublisher<Bool, Never> { started.eraseToAnyPublisher() }
    var roomClosedPublisher: AnyPublisher<String?, Never> { closed.eraseToAnyPublisher() }
    var errorPublisher: AnyPublisher<String?, Never> { errors.eraseToAnyPublisher() }

    func hostRoom(named nickname: String) -> RoomModel? {
        hostedNames.append(nickname)
        return RoomModel(roomName: nickname, hostName: nickname)
    }
    func browseRooms(as nickname: String) { browsedNames.append(nickname) }
    func connect(to room: RoomModel) -> Bool {
        selectedRooms.append(room)
        return canConnect
    }
    func addLocalPlayer(named name: String) { requestedNames.append(name) }
    func sendStartGameSignal() {
        startCount += 1
        if !shouldFailStart { started.send(true) }
    }
    func disconnect() {
        disconnectCount += 1
        roster.send([])
        started.send(false)
    }
    func clearConnectionNotice() { closed.send(nil); errors.send(nil) }
}

@MainActor
private final class RecordingLobbyNavigation: NameInputNavigating, WaitingRoomNavigating {
    var waitingRooms: [RoomModel] = []
    var roomListNames: [String] = []
    var gameCount = 0
    var homeCount = 0
    var backCount = 0

    func showWaitingRoom(_ room: RoomModel) { waitingRooms.append(room) }
    func showRoomList(as nickname: String) { roomListNames.append(nickname) }
    func goBack() { backCount += 1 }
    func showGame() { gameCount += 1 }
    func returnHome() { homeCount += 1 }
}
