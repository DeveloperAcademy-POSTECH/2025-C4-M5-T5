//
//  MPCManager+Guest.swift
//  Yut
//
// Guest 전용 기능 (startBrowsing, browser delegate)
//

import MultipeerConnectivity

extension MPCManager: MCNearbyServiceBrowserDelegate {
    func startBrowsing() {
        isHost = false
        browser?.stopBrowsingForPeers()
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        availableRooms.removeAll()
        browser?.startBrowsingForPeers()
        print("🔍 Browsing started as \(myPeerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        print("🔍 Found Host: \(peerID.displayName)")
        
        let room = RoomModel(
            roomName: "\(peerID.displayName)의 윷놀이방",
            hostName: peerID.displayName,
            players: []
        )
        DispatchQueue.main.async {
            if !self.availableRooms.contains(where: { $0.hostName == peerID.displayName }) {
                self.availableRooms.append(room)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("⚠️ Lost peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.availableRooms.removeAll { $0.hostName == peerID.displayName }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("❌ Failed to browse: \(error.localizedDescription)")
    }
}
