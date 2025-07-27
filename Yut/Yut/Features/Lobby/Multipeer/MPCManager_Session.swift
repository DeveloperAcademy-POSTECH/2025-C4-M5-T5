//
//  MPCManager+Session.swift
//  Yut
//
// 세션 이벤트 및 데이터 송수신 (MCSessionDelegate)
//

import MultipeerConnectivity

extension MPCManager: MCSessionDelegate {
    /// MCSession에서 peer의 연결 상태가 변경될 때 호출됨
    /// - connected: 게스트가 연결되면 Host가 players에 추가하고 업데이트 전송
    /// - notConnected: 연결이 끊기면 connectedPeers에서 제거 후, Host라면 갱신된 리스트 전송
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .connected {
            DispatchQueue.main.async {
                // Host 측에서 새로운 Guest를 players 배열에 추가
                if self.isHost {
                    if !self.players.contains(where: { $0.peerID == peerID }) {
                        let guestPlayer = PlayerModel(
                            name: peerID.displayName,
                            sequence: self.players.count + 1,
                            peerID: peerID,
                            entities: [],
                            isHost: false
                        )
                        self.players.append(guestPlayer)
                    }
                    // Host가 Guest 연결 후 최신 players를 방송하여 Guest UI도 갱신
                    self.sendPlayersUpdate()
                }
            }
        } else if state == .notConnected {
            DispatchQueue.main.async {
                // 연결 해제된 peer 제거
                self.players.removeAll { $0.peerID == peerID }
                self.connectedPeers.removeAll { $0 == peerID }
                if self.isHost {
                    self.broadcastPlayerList()
                }
            }
        }
    }
    
    /// MCSession에서 데이터 수신 시 호출됨
    /// - Host가 전송한 players 배열을 Guest가 수신하여 UI를 업데이트함
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            if let updatedPlayers = try? JSONDecoder().decode([PlayerModel].self, from: data) {
                self.players = updatedPlayers
                print("📥 Updated players: \(self.players.map { $0.name })")
                
                // RoomList에 표시된 Host의 인원수 갱신
                if let roomIndex = self.availableRooms.firstIndex(where: { $0.hostName == peerID.displayName || $0.hostName == self.players.first?.name }) {
                    self.availableRooms[roomIndex].players = updatedPlayers
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    // MARK: - Broadcast Helper

    /// Host가 players 배열 변경 시 모든 Guest에게 최신 상태를 전송하는 헬퍼 메서드
    func broadcastPlayerList() {
        // RoomList에 표시된 인원수도 업데이트
        if let roomIndex = availableRooms.firstIndex(where: { $0.hostName == myPeerID.displayName }) {
            availableRooms[roomIndex].players = players
        }
        
        // 모든 연결된 peer에게 최신 players 데이터를 전송
        if let data = try? JSONEncoder().encode(players) {
            try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
        }
    }
}
