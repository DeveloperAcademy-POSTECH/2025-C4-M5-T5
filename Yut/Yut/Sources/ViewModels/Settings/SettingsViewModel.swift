import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    private let navigator: any SettingsNavigating

    init(navigator: any SettingsNavigating) { self.navigator = navigator }

    func showTerms() { navigator.showLegalDocument(.termsOfService) }
    func showPrivacyPolicy() { navigator.showLegalDocument(.privacyPolicy) }
    func showSupport() { navigator.showSupport() }
    func showCreators() { navigator.showCreators() }
    func goBack() { navigator.goBack() }
}
