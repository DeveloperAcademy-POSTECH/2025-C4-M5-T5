import Foundation

/// 대기실에서 확인한 기기 소유권과 실제 발신 기기를 게임 조정자에게 전달한다.
@MainActor
protocol GameTransporting: AnyObject {
    var isHost: Bool { get }
    var localDeviceID: UUID { get }
    var hostDeviceID: UUID? { get }
    var hasRemotePlayers: Bool { get }
    var gamePlayers: [GamePlayer] { get }
    var onGameMessage: ((GameMessage, UUID) -> Bool)? { get set }
    var onStartGame: (() -> Bool)? { get set }
    var onGameStopped: (() -> Void)? { get set }

    func sendGame(_ message: GameMessage, to recipients: [UUID]?) throws
    func disconnect()
}
