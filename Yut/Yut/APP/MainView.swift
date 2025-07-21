//
//  MainView.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/21/25.
//

import SwiftUI

struct MainView: View {
    @StateObject private var navigationManager = NavigationManager()

    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        HomeView()
                    case .hostNameInput:
                        HostNameInputView()
                    case .roomList:
                        RoomListView()
                    case .waitingRoom(let room):
                        WaitingRoomView(room: room)
                    case .winner:
                        WinnerView()
                    }
                }
        }
        .environmentObject(navigationManager)
    }
}

#Preview {
    MainView()
}
