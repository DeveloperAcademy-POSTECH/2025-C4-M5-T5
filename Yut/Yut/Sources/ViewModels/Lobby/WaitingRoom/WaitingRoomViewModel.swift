import Combine
import Foundation

/// 명단·시작 확정은 연결 어댑터에 위임하고 화면 전환은 한 경로로만 수행한다.
@MainActor
final class WaitingRoomViewModel: ObservableObject {
    @Published var showLeaveAlert = false
    @Published private(set) var players: [PlayerModel] = []
    @Published var errorMessage: String?

    private let session: any WaitingRoomSessionManaging
    private let navigator: any WaitingRoomNavigating
    private var observations: Set<AnyCancellable> = []
    private var hasNavigatedToGame = false
    private var lastClosedReason: String?

    var isHost: Bool { session.isHost }
    var canStartGame: Bool { isHost && (2...4).contains(players.count) && !hasNavigatedToGame }
    var buttonTitle: String {
        guard isHost else { return "방장이 게임을 시작할 때까지 기다려주세요" }
        let titles = [2: "둘이서", 3: "셋이서", 4: "넷이서"]
        return titles[players.count].map { "\($0) 윷놀이 시작하기" } ?? "인원 모으는 중..."
    }

    init(session: any WaitingRoomSessionManaging, navigator: any WaitingRoomNavigating) {
        self.session = session
        self.navigator = navigator
        session.playersPublisher.receive(on: RunLoop.main).assign(to: &$players)
        session.gameStartedPublisher.receive(on: RunLoop.main).sink { [weak self] started in
            guard let self else { return }
            guard started else {
                let hadNavigatedToGame = hasNavigatedToGame
                hasNavigatedToGame = false
                if hadNavigatedToGame, !session.hasStartedGame { navigator.returnHome() }
                return
            }
            // 종료 전에 예약된 시작 알림이 홈 복귀 후 플레이 화면을 다시 열지 않게 한다.
            guard session.hasStartedGame, !hasNavigatedToGame else { return }
            hasNavigatedToGame = true
            navigator.showGame()
        }.store(in: &observations)
        session.roomClosedPublisher.combineLatest(session.errorPublisher)
            .receive(on: RunLoop.main).sink { [weak self] reason, error in
            guard let self else { return }
            // 새 로비가 열린 뒤 도착한 이전 방의 예약 알림은 현재 상태에 반영하지 않는다.
            guard reason == session.roomClosedReason, error == session.connectionError else { return }
            errorMessage = reason ?? error
            if let reason, reason != lastClosedReason { navigator.returnHome() }
            lastClosedReason = reason
        }.store(in: &observations)
    }

    func startGame() {
        guard canStartGame else { return }
        session.sendStartGameSignal()
    }

    func leaveRoom() {
        showLeaveAlert = false
        dismissError()
        session.disconnect()
        navigator.returnHome()
    }

    func dismissError() {
        errorMessage = nil
        session.clearConnectionNotice()
    }
}
