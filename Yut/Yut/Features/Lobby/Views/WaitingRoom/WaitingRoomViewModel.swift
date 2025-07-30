//
//  WaitingRoomViewModel.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/28/25.
//

import Foundation
import MultipeerConnectivity
import Combine

@MainActor
final class WaitingRoomViewModel: ObservableObject {
    @Published var showLeaveAlert = false
    @Published var players: [PlayerModel] = []
    
    private let mpcManager = MPCManager.shared
    private let navigationManager: NavigationManager
    private var cancellables = Set<AnyCancellable>()
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
        MPCManager.shared.$players
            .receive(on: RunLoop.main)
            .assign(to: &$players)
        
        // players를 mpcManager.players와 실시간 동기화
        //        mpcManager.$players
        //            .receive(on: RunLoop.main)
        //            .assign(to: &$players)
    }
    
    // MPC ver.
    //    func addPlayer(name: String) async {
    //        let newPlayer = await PlayerModel.load(
    //            name: name,
    //            sequence: mpcManager.players.count + 1,
    //            peerID: MCPeerID(displayName: name),
    //            isHost: false
    //        )
    //        players.append(newPlayer)
    //        mpcManager.players.append(newPlayer)
    //        if mpcManager.isHost {
    //            mpcManager.sendPlayersUpdate()
    //        }
    //    }
    
    // Single Device ver.
    func addPlayer(named name: String) {
        guard players.count < 4 else { return }
        
        let newPlayer = PlayerModel(
            name: name,
            sequence: players.count + 1,
            peerID: MCPeerID(displayName: name),
            isHost: players.isEmpty
        )
        players.append(newPlayer)
        mpcManager.players.append(newPlayer)
    }
    
    //    func sendStartGameSignal() {
    //        NotificationCenter.default.post(name: .gameStarted, object: nil)
    //    }
    
    func leaveRoom() {
        if mpcManager.isHost {
            // 1. 생성된 방 목록에서 제거
            MPCManager.shared.availableRooms.removeAll {
                $0.hostName == MPCManager.shared.myPeerID.displayName
            }
            // 2. 세션 종료 및 상태 초기화
            mpcManager.disconnect()
            // 3. 홈으로 이동
            navigationManager.popToRoot()
        } else { // 게스트는 본인만 players에서 제거
            if let index = mpcManager.players.firstIndex(where: { $0.peerID == mpcManager.myPeerID }) {
                mpcManager.players.remove(at: index)
            }
            mpcManager.sendPlayersUpdate()
            mpcManager.disconnect()
            navigationManager.pop()
        }
    }
    
    var buttonTitle: String {
        let mapping = [2: "둘이서", 3: "셋이서", 4: "넷이서"]
        // Single Device ver.
        return mapping[players.count].map {"\($0) 윷놀이 시작하기"} ?? "인원 모으는 중..."
        // MPC ver.
        // return mapping[mpcManager.players.count].map { "\($0) 윷놀이 시작하기" } ?? "인원 기다리는 중..."
    }
    
    var isHost: Bool {
        mpcManager.isHost
    }
}

//extension Notification.Name {
//    static let gameStarted = Notification.Name("gameStarted")
//}
