import Combine
import Foundation

@MainActor
protocol LobbySessionManaging: AnyObject {
    var availableRoomsPublisher: AnyPublisher<[RoomModel], Never> { get }

    func hostRoom(named nickname: String) -> RoomModel?
    func browseRooms(as nickname: String)
    func connect(to room: RoomModel) -> Bool
    func disconnect()
}

@MainActor
protocol WaitingRoomSessionManaging: AnyObject {
    var isHost: Bool { get }
    var hasStartedGame: Bool { get }
    var roomClosedReason: String? { get }
    var connectionError: String? { get }
    var playersPublisher: AnyPublisher<[PlayerModel], Never> { get }
    var gameStartedPublisher: AnyPublisher<Bool, Never> { get }
    var roomClosedPublisher: AnyPublisher<String?, Never> { get }
    var errorPublisher: AnyPublisher<String?, Never> { get }

    func addLocalPlayer(named name: String)
    func sendStartGameSignal()
    func disconnect()
    func clearConnectionNotice()
}

extension MPCManager: LobbySessionManaging, WaitingRoomSessionManaging {
    var availableRoomsPublisher: AnyPublisher<[RoomModel], Never> { $availableRooms.eraseToAnyPublisher() }
    var playersPublisher: AnyPublisher<[PlayerModel], Never> { $players.eraseToAnyPublisher() }
    var gameStartedPublisher: AnyPublisher<Bool, Never> { $hasStartedGame.eraseToAnyPublisher() }
    var roomClosedPublisher: AnyPublisher<String?, Never> { $roomClosedReason.eraseToAnyPublisher() }
    var errorPublisher: AnyPublisher<String?, Never> { $connectionError.eraseToAnyPublisher() }
}
