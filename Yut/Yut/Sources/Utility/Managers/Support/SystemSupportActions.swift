import UIKit

@MainActor
final class SystemSupportActions: SupportActions {
    private let application: UIApplication

    init(application: UIApplication) {
        self.application = application
    }

    func openChat(at url: URL) async -> Bool {
        return await application.open(url)
    }
}
