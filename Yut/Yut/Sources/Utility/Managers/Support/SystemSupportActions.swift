import UIKit

@MainActor
final class SystemSupportActions: SupportActions {
    private let application: UIApplication
    private let pasteboard: UIPasteboard

    init(application: UIApplication, pasteboard: UIPasteboard) {
        self.application = application
        self.pasteboard = pasteboard
    }

    func openEmail(to address: String, subject: String, body: String) async -> Bool {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = address
        components.queryItems = [URLQueryItem(name: "subject", value: subject), URLQueryItem(name: "body", value: body)]
        guard let url = components.url else { return false }
        return await application.open(url)
    }

    func copyEmail(_ address: String) { pasteboard.string = address }
}
