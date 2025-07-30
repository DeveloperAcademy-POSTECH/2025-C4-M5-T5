//
//  MainView.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/21/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var navigationManager = NavigationManager()
    @StateObject private var viewModel: WaitingRoomViewModel
    private let arCoordinator = ARCoordinator()

    init() {
        let manager = NavigationManager()
        _navigationManager = StateObject(wrappedValue: manager)
        _viewModel = StateObject(wrappedValue: WaitingRoomViewModel(navigationManager: manager))
    }

    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        HomeView()
                    case .hostNameInput:
                        HostNameInputView()
                    case .guestNameInput:
                        GuestNameInputView()
                    case .roomList:
                        RoomListView()
                    case .waitingRoom(let room):
                        WaitingRoomView(
                            room: room,
                            navigationManager: navigationManager,
                            arCoordinator: arCoordinator
                        )
                        .environmentObject(viewModel)
                    case .winner:
                        WinnerView()
                    case .playView:
                        PlayView(arCoordinator: arCoordinator)
                            .environmentObject(viewModel)
                    }
                }
        }
        .environmentObject(navigationManager)
    }
}

#Preview {
    RootView()
}
