//
//  MainView.swift
//  YUT
//
//  Created by Hwnag Seyeon on 7/21/25.
//

import AVFoundation
import SwiftUI

struct RootView: View {
    @ObservedObject private var navigationManager: NavigationManager
    @ObservedObject private var viewModel: WaitingRoomViewModel
    @ObservedObject private var playViewModel: PlayViewModel
    private let homeViewModel: HomeViewModel
    private let game: GameSessionController
    private let lobbySession: any LobbySessionManaging
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        navigationManager = dependencies.navigation
        viewModel = dependencies.waitingRoom
        playViewModel = dependencies.play
        homeViewModel = dependencies.home
        game = dependencies.game
        lobbySession = dependencies.session
        self.dependencies = dependencies
    }

    var body: some View {
        ZStack {
            NavigationStack(path: $navigationManager.path) {
                HomeView(viewModel: homeViewModel)
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .home:
                            HomeView(viewModel: homeViewModel)
                        case .localPlay:
                            LocalPlayView(viewModel: dependencies.makeLocalPlayViewModel())
                        case .hostNameInput:
                            HostNameInputView(
                                viewModel: HostNameInputViewModel(
                                    session: lobbySession,
                                    navigator: navigationManager
                                )
                            )
                        case .guestNameInput:
                            GuestNameInputView(
                                viewModel: GuestNameInputViewModel(
                                    session: lobbySession,
                                    navigator: navigationManager
                                )
                            )
                        case .roomList:
                            RoomListView(viewModel: RoomListViewModel(session: lobbySession, navigator: navigationManager))
                        case .waitingRoom(let room):
                            WaitingRoomView(room: room)
                            .environmentObject(viewModel)
                        case .playView:
                            PlayView(viewModel: playViewModel)
                        case .winner:
                            WinnerView(viewModel: WinnerViewModel(game: game))
                        case .settings:
                            SettingsView(viewModel: dependencies.settings)
                        case .legalDocument(let kind):
                            LegalDocumentView(viewModel: dependencies.makeLegalDocumentViewModel(kind))
                        case .creators:
                            CreatorsView(viewModel: dependencies.creators)
                        }
                    }
            }
            .tint(ThemeColors.textPrimary)
            .accessibilityHidden(viewModel.errorMessage != nil || playViewModel.errorMessage != nil)
            .allowsHitTesting(viewModel.errorMessage == nil && playViewModel.errorMessage == nil)
            if let message = viewModel.errorMessage {
                AppNoticeView(title: "연결 안내", message: message, primaryTitle: "확인", onPrimary: viewModel.dismissError)
                    .zIndex(10)
            } else if let message = playViewModel.errorMessage {
                AppNoticeView(title: "게임 안내", message: message, primaryTitle: "다시 시도", onPrimary: playViewModel.retry,
                    secondaryTitle: "방 나가기", onSecondary: playViewModel.leaveRoom)
                    .zIndex(10)
            }
        }
    }
}

//#Preview {
//    RootView()
//}
