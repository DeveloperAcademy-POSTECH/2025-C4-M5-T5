import Combine

/// 홈의 사용자 의도를 전달하며 구체적인 route 선택은 내비게이션 계층에 맡긴다.
@MainActor
final class HomeViewModel: ObservableObject {
    private let navigator: any HomeNavigating

    init(navigator: any HomeNavigating) { self.navigator = navigator }

    func createRoom() { navigator.showHostNameInput() }
    func joinRoom() { navigator.showGuestNameInput() }
    func showSettings() { navigator.showSettings() }
}
