import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var isOpeningSupport = false
    @Published var isShowingSupportError = false

    private let navigator: any SettingsNavigating
    private let supportActions: any SupportActions
    private let supportChatURL: URL?

    init(navigator: any SettingsNavigating, supportActions: any SupportActions, supportChatURL: URL?) {
        self.navigator = navigator
        self.supportActions = supportActions
        self.supportChatURL = supportChatURL
    }

    func showTerms() { navigator.showLegalDocument(.termsOfService) }
    func showPrivacyPolicy() { navigator.showLegalDocument(.privacyPolicy) }
    func showCreators() { navigator.showCreators() }
    func goBack() { navigator.goBack() }

    func openSupport() async {
        guard !isOpeningSupport else { return }
        isShowingSupportError = false
        guard let supportChatURL else {
            isShowingSupportError = true
            return
        }
        isOpeningSupport = true
        defer { isOpeningSupport = false }
        isShowingSupportError = !(await supportActions.openChat(at: supportChatURL))
    }
}
