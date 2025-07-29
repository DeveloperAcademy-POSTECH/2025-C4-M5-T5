//
//  MPCManager+Host.swift
//  Yut
//
// Host 전용 기능 (startHosting, advertiser delegate)
//

import MultipeerConnectivity

extension MPCManager: MCNearbyServiceAdvertiserDelegate {
    func startAdvertising() {
        isHost = true
        if session == nil {
            session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
            session.delegate = self
        }

        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        print("📡 Advertising started as \(myPeerID.displayName)")
        print("📡 advertiser.delegate: \(advertiser?.delegate != nil)")
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("✅ Host: 초대 받음 from \(peerID.displayName)")   
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
    
    func sendStartGameSignal() {
        let message = "startGame"
        if let data = message.data(using: .utf8) {
            try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
        }
    }
}
