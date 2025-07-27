//
//  MPCManager.swift
//  Yut
//
// 공용 프로퍼티 & 초기화, 상태 관리
//

import MultipeerConnectivity

class MPCManager: NSObject, ObservableObject {
    static let shared = MPCManager()
    
    let serviceType = "yut-game"
    let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    var session: MCSession!
    var advertiser: MCNearbyServiceAdvertiser?
    var browser: MCNearbyServiceBrowser?
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var isHost: Bool = false
    
    override init() {
        super.init()
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }
}
