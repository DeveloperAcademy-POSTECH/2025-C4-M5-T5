import SwiftUI

@main
struct YutApp: App {
    @StateObject private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup { RootView(dependencies: dependencies) }
    }
}
