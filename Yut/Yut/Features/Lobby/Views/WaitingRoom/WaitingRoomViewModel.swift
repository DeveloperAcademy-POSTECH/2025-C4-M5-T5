//
//  WaitingRoomViewModel.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/28/25.
//

import Foundation
import MultipeerConnectivity

@MainActor
final class WaitingRoomViewModel: ObservableObject {
    @Published var showLeaveAlert = false
    @Published var players: [PlayerModel] = []

    private let mpcManager = MPCManager.shared
    private let navigationManager: NavigationManager

    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
        self.players = mpcManager.players
    }

    func addPlayer(name: String) async {
        let newPlayer = await PlayerModel.load(
            name: name,
            sequence: mpcManager.players.count + 1,
            peerID: MCPeerID(displayName: name),
            isHost: false
        )
        players.append(newPlayer)
        mpcManager.players.append(newPlayer)
        if mpcManager.isHost {
            mpcManager.sendPlayersUpdate()
        }
    }

    func leaveRoom() {
        if mpcManager.isHost {
            mpcManager.disconnect()
            navigationManager.popToRoot()
        } else {
            if let index = mpcManager.players.firstIndex(where: { $0.peerID == mpcManager.myPeerID }) {
                mpcManager.players.remove(at: index)
            }
            mpcManager.sendPlayersUpdate()
            mpcManager.disconnect()
            navigationManager.popToRoot()
        }
    }

    var buttonTitle: String {
        let mapping = [2: "둘이서", 3: "셋이서", 4: "넷이서"]
        return mapping[mpcManager.players.count].map { "\($0) 윷놀이 시작하기" } ?? "인원 기다리는 중..."
    }

    var isHost: Bool {
        mpcManager.isHost
    }
}
