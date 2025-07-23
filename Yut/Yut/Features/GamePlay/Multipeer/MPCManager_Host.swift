//
//  MPCManager+Host.swift
//  Yut
//
// Host 전용 기능 (startHosting, advertiser delegate)
//

import MultipeerConnectivity

extension MPCManager: MCNearbyServiceAdvertiserDelegate {
    func startHosting() {
        isHost = true
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // 최대 3명까지 허용
        if connectedPeers.count < 3 {
            invitationHandler(true, session)
        } else {
            invitationHandler(false, nil)
        }
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ Failed to advertise: \(error.localizedDescription)")
    }
}
