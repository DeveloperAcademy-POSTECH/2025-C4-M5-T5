import Combine
import Foundation

@MainActor
final class SupportViewModel: ObservableObject {
    @Published private(set) var notice: String?
    @Published private(set) var isOpeningEmail = false
    let email: String?
    private let appVersion: String
    private let actions: any SupportActions
    private let navigator: any SettingsNavigating

    var canContact: Bool { email != nil }

    init(email: String?, appVersion: String, actions: any SupportActions, navigator: any SettingsNavigating) {
        let trimmed = email?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = trimmed.flatMap { $0.isEmpty ? nil : $0 }
        self.appVersion = appVersion
        self.actions = actions
        self.navigator = navigator
    }

    func composeEmail() async {
        guard let email, !isOpeningEmail else { return }
        isOpeningEmail = true
        defer { isOpeningEmail = false }
        let opened = await actions.openEmail(to: email, subject: "윷(Yut) 문의", body: "앱 버전: \(appVersion)\n\n문의 내용:\n")
        notice = opened ? nil : "메일 앱을 열지 못했습니다. 이메일 주소를 복사해 문의해주세요."
    }

    func copyEmail() {
        guard let email else { return }
        actions.copyEmail(email)
        notice = "이메일 주소를 복사했습니다."
    }

    func goBack() { navigator.goBack() }
}
