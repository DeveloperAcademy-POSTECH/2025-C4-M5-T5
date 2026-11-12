import Combine

@MainActor
final class CreatorsViewModel: ObservableObject {
    let creators = AppInformation.creators
    private let navigator: any SettingsNavigating

    init(navigator: any SettingsNavigating) { self.navigator = navigator }

    func goBack() { navigator.goBack() }
}
