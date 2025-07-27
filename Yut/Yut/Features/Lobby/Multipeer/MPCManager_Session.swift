//
//  MPCManager+Session.swift
//  Yut
//
// 세션 이벤트 및 데이터 송수신 (MCSessionDelegate)
//

import MultipeerConnectivity

extension MPCManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                    if self.isHost { self.broadcastPlayerList() }
                }
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                if self.isHost { self.broadcastPlayerList() }
            default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // 데이터 수신 처리 (Guest: Host로부터 PlayerList 받기)
        if let decoded = try? JSONDecoder().decode([String: [String]].self, from: data),
           let nicknames = decoded["playerList"], isHost == false
        {
            print("📥 받은 플레이어 목록: \(nicknames)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    // MARK: - Broadcast Helper

    func broadcastPlayerList() {
        let nicknames = connectedPeers.map { $0.displayName }
        if let data = try? JSONEncoder().encode(["playerList": nicknames]) {
            try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
        }
    }
}
