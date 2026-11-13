import Combine

/// 선택 슬롯은 구성 화면만 소유하고, 시작 시 기존 게임 세션에 참가 명단을 전달한다.
@MainActor
final class LocalPlayViewModel: ObservableObject {
    @Published private(set) var selectedSlots: Set<Int> = [1, 2]
    @Published private(set) var hasStarted = false
    @Published private(set) var errorMessage: String?
    private let session: any LocalPlaySessionManaging
    private let navigator: any WaitingRoomNavigating

    var canStart: Bool { (2...4).contains(selectedSlots.count) && !hasStarted }

    var buttonTitle: String {
        let titles = [2: "둘이서", 3: "셋이서", 4: "넷이서"]
        return titles[selectedSlots.count].map { "\($0) 윷놀이 시작하기" } ?? "인원 모으는 중..."
    }

    init(session: any LocalPlaySessionManaging, navigator: any WaitingRoomNavigating) {
        self.session = session
        self.navigator = navigator
    }

    func togglePlayer(slot: Int) {
        guard !hasStarted, (1...4).contains(slot) else { return }
        if selectedSlots.contains(slot) { selectedSlots.remove(slot) }
        else { selectedSlots.insert(slot) }
        errorMessage = nil
    }

    func startGame() {
        guard canStart else { return }
        // 시작 콜백이 화면을 전환하는 동안 중복 입력을 차단한다.
        hasStarted = true
        if !session.startLocalGame(slots: selectedSlots) {
            hasStarted = false
            errorMessage = "게임을 시작하지 못했습니다. 다시 시도해주세요."
        }
    }

    func dismissError() { errorMessage = nil }

    func goBack() { navigator.returnHome() }
}
