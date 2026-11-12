@MainActor
protocol SupportActions: AnyObject {
    func openEmail(to address: String, subject: String, body: String) async -> Bool
    func copyEmail(_ address: String)
}
