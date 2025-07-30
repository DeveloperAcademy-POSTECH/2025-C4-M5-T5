//
//  MPCManager.swift
//  Yut
//
// 공용 프로퍼티 & 초기화, 상태 관리
//

import MultipeerConnectivity

class MPCManager: NSObject, ObservableObject {
    static let shared = MPCManager()
    
    let serviceType = "yutgame"
    var myPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    var session: MCSession!
    var advertiser: MCNearbyServiceAdvertiser?
    var browser: MCNearbyServiceBrowser?
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var players: [PlayerModel] = []
    @Published var availableRooms: [RoomModel] = []
    @Published var isHost: Bool = false
    
    override init() {
        super.init()
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }
    
    func addHostPlayer(name: String) {
        let hostPlayer = PlayerModel(
            name: name,
            sequence: 1,
            peerID: myPeerID,
//            entities: [],
            isHost: true
        )
        players.append(hostPlayer)
        print("✅ Host added: \(hostPlayer.name), sequence: \(hostPlayer.sequence), profile: \(hostPlayer.profile)")
        
        if let roomIndex = availableRooms.firstIndex(where: { $0.hostName == myPeerID.displayName }) {
            availableRooms[roomIndex].players = players
        } else {
            let newRoom = RoomModel(
                roomName: "\(myPeerID.displayName)의 윷놀이방",
                hostName: myPeerID.displayName,
                players: players
            )
            availableRooms.append(newRoom)
        }
        
        sendPlayersUpdate()
    }

    func addGuestPlayer(peerID: MCPeerID) {
        let guestPlayer = PlayerModel(
            name: peerID.displayName,
            sequence: players.count + 1,
            peerID: peerID
//            entities: []
        )
        players.append(guestPlayer)
        print("✅ Guest added: \(guestPlayer.name), sequence: \(guestPlayer.sequence), profile: \(guestPlayer.profile)")
    }
    
//    func disconnect() {
//        session.disconnect()
//        players.removeAll()
//        print("🔌 Disconnected and players reset")
//    }
    func disconnect() {
        // Ensure session is non-nil before disconnecting
        if session == nil {
            session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
            session.delegate = self
        }
        
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        browser?.stopBrowsingForPeers()
        browser = nil
        session?.disconnect()
        session = nil
        connectedPeers = []
        players = []
        print("🔌 Disconnected and players reset")
    }
    
    func updatePeerIDAndSession(with displayName: String) {
        myPeerID = MCPeerID(displayName: displayName)
        session.disconnect()
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }
    
    func configurePeerAndSession(with displayName: String) {
         myPeerID = MCPeerID(displayName: displayName)
         session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
         session.delegate = self
     }
}

extension MPCManager {
    func sendPlayersUpdate() {
        if let data = try? JSONEncoder().encode(players) {
            try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
        }
    }
}
