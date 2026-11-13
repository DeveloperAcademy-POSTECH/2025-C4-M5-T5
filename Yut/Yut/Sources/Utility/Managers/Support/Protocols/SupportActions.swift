import Foundation

@MainActor
protocol SupportActions: AnyObject {
    func openChat(at url: URL) async -> Bool
}
