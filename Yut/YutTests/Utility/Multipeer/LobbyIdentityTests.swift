import Foundation
import MultipeerConnectivity
import Testing
@testable import Yut

@MainActor
struct LobbyIdentityTests {
    @Test
    func localGameKeepsSlotNamesColorsAndAuthorityWithoutNetwork() throws {
        let manager = MPCManager()
        defer { manager.disconnect() }
        let game = GameSessionController(transport: manager)
        #expect(manager.startLocalGame(slots: [2, 4]))
        #expect(manager.players.map(\.name) == ["플레이어 2", "플레이어 4"])
        #expect(manager.players.map(\.sequence) == [2, 4])
        #expect(manager.players.allSatisfy { $0.deviceID == manager.localDeviceID })
        #expect(manager.isLocalPlay && manager.hasStartedGame && game.canAct)
        #expect(manager.session == nil && manager.advertiser == nil && manager.browser == nil)
        manager.startAdvertising()
        manager.startBrowsing()
        let outsider = MCPeerID(displayName: "Guest")
        #expect(!manager.acceptInvitation(from: outsider))
        manager.peer(outsider, changedTo: .connected)
        manager.receive(try JSONEncoder().encode(LobbyMessage.hello(UUID())), from: outsider)
        #expect(!manager.hasRemotePlayers)
        #expect(manager.advertiser == nil && manager.browser == nil)
        #expect(manager.players.count == 2)
        #expect(!manager.startLocalGame(slots: [1, 3]))
        var state = try #require(game.state)
        try state.apply(.startPlaying)
        for _ in 0..<2 {
            #expect(state.currentPlayer?.deviceID == manager.localDeviceID)
            for action: GameAction in [.beginThrow, .armThrow, .releaseThrow(launch: .testLaunch),
                                      .recordThrow(.backdho), .dismissResult] { try state.apply(action) }
        }
        #expect(state.pieces.count == 4)
        manager.disconnect()
        #expect(game.state == nil && manager.players.isEmpty && !manager.isLocalPlay)
        #expect(manager.hostRoom(named: "Host") != nil)
        #expect(manager.advertiser != nil && !manager.isLocalPlay)
        #expect(manager.players.count == 1)
    }

    @Test
    func invalidLocalRosterDoesNotReplaceExistingRoomAndMultiplayerRejectsExtraPlayer() throws {
        let manager = MPCManager()
        defer { manager.disconnect() }
        #expect(manager.hostRoom(named: "Host") != nil)
        let host = try #require(manager.players.first)
        for slots: Set<Int> in [[], [1], [1, 5], [0, 1, 2, 3, 4]] {
            #expect(!manager.startLocalGame(slots: slots))
            #expect(manager.players.first === host)
        }
        let peer = MCPeerID(displayName: "Guest")
        #expect(manager.acceptInvitation(from: peer))
        manager.peer(peer, changedTo: .connected)
        let identity = UUID()
        manager.receive(try JSONEncoder().encode(LobbyMessage.hello(identity)), from: peer)
        manager.receive(try JSONEncoder().encode(LobbyMessage.hello(identity)), from: peer)
        manager.receive(try JSONEncoder().encode(LobbyMessage.addPlayer("Extra")), from: peer)
        #expect(manager.players.count == 2)
        #expect(Set(manager.gamePlayers.map(\.deviceID)).count == 2)
    }

    @Test
    func incompatibleUUIDPeerIsNotPresentedAsJoinableRoom() {
        let manager = MPCManager()
        defer { manager.disconnect() }
        let peer = MCPeerID(displayName: UUID().uuidString)

        // YutAR은 같은 serviceType을 쓰지만 방 검색·초대·메시지 형식이 다르다.
        manager.foundPeer(peer, info: ["hostName": "친구", "playerCount": "1", "version": "3"])

        #expect(manager.availableRooms.isEmpty)
    }

    @Test
    func roomAdvertisementCarriesNicknameSeparatelyFromPeerIdentity() throws {
        let manager = MPCManager()
        defer { manager.disconnect() }
        let room = try #require(manager.hostRoom(named: "친구"))
        let info = try #require(manager.advertiser?.discoveryInfo)

        #expect(info["hostName"] == "친구")
        #expect(info["roomID"] == room.id.uuidString)
        #expect(info["players"] == "1")
    }

    @Test
    func validRoomUsesAdvertisedNicknameAndReplacesPreviousRoomForSamePeer() throws {
        let manager = MPCManager()
        defer { manager.disconnect() }
        let peer = MCPeerID(displayName: UUID().uuidString)
        let previous = UUID()
        let current = UUID()
        manager.foundPeer(peer, info: ["roomID": previous.uuidString, "players": "1", "hostName": "이전 방장"])
        manager.foundPeer(peer, info: ["roomID": current.uuidString, "players": "2", "hostName": "새 방장"])

        let room = try #require(manager.availableRooms.first)
        #expect(manager.availableRooms.count == 1)
        #expect(room.id == current)
        #expect(room.hostName == "새 방장")
        #expect(room.currentPlayers == 2)
    }

    @Test
    func invalidAdvertisementCannotCreateOrKeepRoomCard() {
        let manager = MPCManager()
        defer { manager.disconnect() }
        let peer = MCPeerID(displayName: "Host")
        let id = UUID().uuidString
        let invalidAdvertisements: [[String: String]?] = [
            nil, [:], ["roomID": id], ["players": "1"],
            ["roomID": "invalid", "players": "1"],
            ["roomID": id, "players": "0"], ["roomID": id, "players": "5"],
            ["roomID": id, "players": "invalid"],
            ["roomID": id, "players": "1", "hostName": " \n "]
        ]
        for info in invalidAdvertisements {
            manager.foundPeer(peer, info: ["roomID": id, "players": "1"])
            #expect(manager.availableRooms.count == 1)
            manager.foundPeer(peer, info: info)
            #expect(manager.availableRooms.isEmpty)
        }
    }

    @Test
    func handshakeBindsDeviceIdentityToNativePeerAndRejectsReplacement() throws {
        let manager = MPCManager()
        defer { manager.disconnect() }
        _ = manager.hostRoom(named: "Host")
        let peer = MCPeerID(displayName: "Guest")
        let device = UUID()
        manager.receive(try JSONEncoder().encode(LobbyMessage.hello(device)), from: peer)
        #expect(manager.players.count == 1)
        #expect(manager.acceptInvitation(from: peer))
        manager.peer(peer, changedTo: .connected)
        manager.receive(try JSONEncoder().encode(LobbyMessage.hello(device)), from: peer)
        #expect(manager.players.count == 2)
        #expect(manager.players.last?.deviceID == device)
        manager.receive(try JSONEncoder().encode(LobbyMessage.hello(UUID())), from: peer)
        #expect(manager.players.last?.deviceID == device)
        manager.peer(peer, changedTo: .notConnected)
        #expect(manager.players.count == 1)
    }

    @Test
    func playerRoundTripPreservesPlayerAndPeerIdentity() throws {
        let peer = MCPeerID(displayName: "Host")
        let player = PlayerModel(name: "Host", sequence: 1, peerID: peer, isHost: true)
        let restored = try JSONDecoder().decode(PlayerModel.self, from: JSONEncoder().encode(player))
        #expect(restored.id == player.id)
        #expect(restored.peerID == peer)
        #expect(restored.sequence == 1)
        #expect(restored.pieces.count == 2)
    }

    @Test
    func roomsWithSameDisplayNameRemainDistinctAndDiscoveryDoesNotAutoConnect() throws {
        let manager = MPCManager()
        defer { manager.disconnect() }
        let first = MCPeerID(displayName: "Host")
        let second = MCPeerID(displayName: "Host")
        let id = UUID()
        manager.foundPeer(first, info: ["roomID": id.uuidString, "players": "2"])
        manager.foundPeer(second, info: ["roomID": UUID().uuidString, "players": "1"])
        #expect(manager.availableRooms.count == 2)
        #expect(manager.availableRooms.first?.currentPlayers == 2)
        #expect(manager.connectedPeers.isEmpty)
        manager.foundPeer(first, info: ["roomID": id.uuidString, "players": "3"])
        #expect(manager.availableRooms.count == 2)
        #expect(manager.availableRooms.first?.id == id)
        #expect(manager.availableRooms.first?.currentPlayers == 3)
        manager.lostPeer(first)
        #expect(manager.availableRooms.count == 1)
        #expect(manager.availableRooms.first?.id != id)
    }

    @Test
    func unsolicitedStartAndRoomClosureDoNotChangeSession() throws {
        let manager = MPCManager()
        defer { manager.disconnect() }
        let outsider = MCPeerID(displayName: "Other")
        manager.receive(try JSONEncoder().encode(LobbyMessage.startGame(UUID())), from: outsider)
        manager.receive(try JSONEncoder().encode(LobbyMessage.roomClosed), from: outsider)
        #expect(!manager.hasStartedGame)
        #expect(manager.roomClosedReason == nil)
        #expect(manager.session != nil)
    }

    @Test
    func invalidPlayerSequenceIsRejectedBeforeLoadingPieceModels() throws {
        let player = PlayerModel(name: "Host", sequence: 1, peerID: MCPeerID(displayName: "Host"))
        let encoded = try JSONEncoder().encode(player)
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object["sequence"] = 5
        let invalid = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(PlayerModel.self, from: invalid) }
    }

    @Test
    func pendingInvitationsReservePlayerSlotsAndBlockPrematureStart() throws {
        let manager = MPCManager()
        defer { manager.disconnect() }
        let game = GameSessionController(transport: manager)
        _ = try #require(manager.hostRoom(named: "Host"))
        let peer = MCPeerID(displayName: "Joining")
        let accepted = manager.acceptInvitation(from: peer)
        #expect(accepted)
        manager.sendStartGameSignal()
        #expect(!manager.hasStartedGame)
        manager.peer(peer, changedTo: .notConnected)
        manager.sendStartGameSignal()
        #expect(!manager.hasStartedGame)
        #expect(game.state == nil)
        // 연결된 적 없는 피어의 종료 이벤트가 진행 중인 방을 닫으면 안 된다.
        manager.peer(peer, changedTo: .notConnected)
        #expect(!manager.hasStartedGame)
        #expect(manager.roomClosedReason == nil)
    }

    @Test
    func invitationsReserveEveryRemainingSlot() throws {
        let manager = MPCManager()
        defer { manager.disconnect() }
        _ = try #require(manager.hostRoom(named: "Host"))
        for name in ["A", "B", "C"] {
            let accepted = manager.acceptInvitation(from: MCPeerID(displayName: name))
            #expect(accepted)
        }
        #expect(manager.players.count == 1)
        let accepted = manager.acceptInvitation(from: MCPeerID(displayName: "Full"))
        #expect(!accepted)
    }
}
