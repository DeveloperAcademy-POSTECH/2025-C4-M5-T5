import Combine
import Foundation
import MultipeerConnectivity
import OSLog
import UIKit

/// 기존 AR 코드의 연결 객체는 유지하고, 대기실의 상태 변경 진입점은 메인 액터로 모은다.
/// SDK delegate는 콜백 파일에서 메인 액터로 전달하며 이전 세션의 늦은 콜백은 무시한다.
@MainActor
final class MPCManager: NSObject, ObservableObject, GameTransporting {
    private enum LobbyError: LocalizedError {
        case invalidRoster
        var errorDescription: String? { "참가자 명단을 확인하지 못했습니다. 방에 다시 참여해주세요." }
    }

    @Published private(set) var connectedPeers: [MCPeerID] = []
    @Published private(set) var players: [PlayerModel] = []
    @Published private(set) var availableRooms: [RoomModel] = []
    @Published private(set) var isHost = false
    @Published private(set) var hasStartedGame = false
    @Published private(set) var roomClosedReason: String?
    @Published private(set) var connectionError: String?

    static let shared = MPCManager()
    let serviceType = "yutgame"
    let localDeviceID = UUID()
    @MainActor var onGameMessage: ((GameMessage, UUID) -> Bool)?
    @MainActor var onStartGame: (() -> Bool)?
    @MainActor var onGameStopped: (() -> Void)?
    private let logger = Logger(subsystem: "Yut", category: "Lobby")
    private(set) var myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private(set) var session: MCSession?
    private(set) var advertiser: MCNearbyServiceAdvertiser?
    private(set) var browser: MCNearbyServiceBrowser?
    private var discoveredPeers: [UUID: MCPeerID] = [:]
    private var hostPeerID: MCPeerID?
    private var peerDeviceIDs: [MCPeerID: UUID] = [:]
    private var hostedRoomID = UUID()
    private var pendingPeers: Set<MCPeerID> = []
    private var invitationTasks: [MCPeerID: Task<Void, Never>] = [:]

    @MainActor var hasRemotePlayers: Bool { !connectedPeers.isEmpty }
    @MainActor var hostDeviceID: UUID? {
        if isHost { return localDeviceID }
        guard let hostPeerID else { return nil }
        return peerDeviceIDs[hostPeerID]
    }
    @MainActor var gamePlayers: [GamePlayer] {
        players.map { GamePlayer(id: $0.id, name: $0.name, order: $0.sequence - 1, deviceID: $0.deviceID) }
    }

    @MainActor
    func sendGame(_ message: GameMessage, to recipients: [UUID]?) throws {
        let peers: [MCPeerID]
        if let recipients {
            let requested = Set(recipients).subtracting([localDeviceID])
            peers = connectedPeers.filter { peerDeviceIDs[$0].map(requested.contains) == true }
            guard peers.count == requested.count else { throw LobbyError.invalidRoster }
        } else { peers = connectedPeers }
        guard !peers.isEmpty else { return }
        guard let session else { throw LobbyError.invalidRoster }
        let mode: MCSessionSendDataMode
        switch message {
        case .throwFrame(let frame): mode = frame.isFinal ? .reliable : .unreliable
        case .collaboration(_, _, let critical): mode = critical ? .reliable : .unreliable
        default: mode = .reliable
        }
        try session.send(JSONEncoder().encode(LobbyMessage.game(message)), toPeers: peers, with: mode)
    }

    override init() {
        super.init()
        replaceSession()
    }

    func clearConnectionNotice() {
        roomClosedReason = nil
        connectionError = nil
    }

    @MainActor
    func hostRoom(named nickname: String) -> RoomModel? {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        configurePeerAndSession(with: name)
        isHost = true
        hostedRoomID = UUID()
        players = [PlayerModel(name: name, sequence: 1, peerID: myPeerID, isHost: true, deviceID: localDeviceID, preparePieces: false)]
        startAdvertising()
        return RoomModel(id: hostedRoomID, roomName: "\(name)의 윷놀이방", hostName: name, players: players)
    }

    @MainActor
    func browseRooms(as nickname: String) {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        configurePeerAndSession(with: name)
        startBrowsing()
    }

    /// 같은 표시 이름으로 만든 새 MCPeerID 대신 탐색 콜백에서 받은 실제 피어에 연결한다.
    @MainActor
    func connect(to room: RoomModel) -> Bool {
        guard !isHost, let browser, let session, let peer = discoveredPeers[room.id], room.currentPlayers < room.maxPlayers else {
            connectionError = "방에 연결할 수 없습니다. 목록에서 다시 선택해주세요."
            return false
        }
        connectionError = nil
        hostPeerID = peer
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 10)
        return true
    }

    @MainActor
    func addLocalPlayer(named name: String) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !hasStartedGame, players.count < 4 else { return }
        if isHost {
            appendPlayer(named: name, peer: myPeerID)
            sendPlayersUpdate()
        } else if let hostPeerID {
            _ = send(.addPlayer(name), to: [hostPeerID])
        }
    }

    @MainActor
    func sendStartGameSignal() {
        guard isHost, !hasStartedGame, (2...4).contains(players.count) else { return }
        guard pendingPeers.isEmpty, connectedPeers.allSatisfy({ peerDeviceIDs[$0] != nil }) else {
            connectionError = "참가자의 연결이 완료된 뒤 게임을 시작해주세요."
            return
        }
        do {
            guard send(.players(try snapshots())), onStartGame?() == true else { return }
            advertiser?.stopAdvertisingPeer()
            hasStartedGame = true
        } catch { report(error) }
    }

    @MainActor
    func disconnect() {
        if isHost { _ = send(.roomClosed) }
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
        invitationTasks.values.forEach { $0.cancel() }
        invitationTasks = [:]
        pendingPeers = []
        session?.delegate = nil
        session?.disconnect()
        session = nil
        connectedPeers = []
        players = []
        availableRooms = []
        discoveredPeers = [:]
        hostPeerID = nil
        peerDeviceIDs = [:]
        isHost = false
        hasStartedGame = false
        connectionError = nil
        onGameStopped?()
    }

    @MainActor
    func startAdvertising() {
        guard isHost, !hasStartedGame, let host = players.first(where: \.isHost) else { return }
        advertiser?.stopAdvertisingPeer()
        let info = ["roomID": hostedRoomID.uuidString, "players": String(players.count), "hostName": host.name]
        let advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: info, serviceType: serviceType)
        advertiser.delegate = self
        self.advertiser = advertiser
        advertiser.startAdvertisingPeer()
    }

    @MainActor
    func startBrowsing() {
        browser?.stopBrowsingForPeers()
        let browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser.delegate = self
        self.browser = browser
        browser.startBrowsingForPeers()
    }

    @MainActor
    func foundPeer(_ peer: MCPeerID, info: [String: String]?) {
        guard !isHost else { return }
        // 같은 탐색 채널의 YutAR 등은 다른 초대·메시지 형식을 쓰므로 방 ID를 임의 생성하지 않는다.
        guard let info, let id = info["roomID"].flatMap(UUID.init(uuidString:)),
              let count = info["players"].flatMap(Int.init), (1...4).contains(count) else {
            lostPeer(peer)
            return
        }
        // 이전 Yut의 광고에는 hostName이 없으므로 해당 형식에 한해 피어의 닉네임을 사용한다.
        let name = (info["hostName"] ?? peer.displayName).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            lostPeer(peer)
            return
        }
        if discoveredPeers.contains(where: { $0.value == peer && $0.key != id }) { lostPeer(peer) }
        discoveredPeers[id] = peer
        let room = RoomModel(id: id, roomName: "\(name)의 윷놀이방", hostName: name, advertisedPlayerCount: count)
        if let index = availableRooms.firstIndex(where: { $0.id == id }) { availableRooms[index] = room }
        else { availableRooms.append(room) }
    }

    @MainActor
    func lostPeer(_ peer: MCPeerID) {
        let ids = Set(discoveredPeers.filter { $0.value == peer }.map(\.key))
        availableRooms.removeAll { ids.contains($0.id) }
        discoveredPeers = discoveredPeers.filter { !ids.contains($0.key) }
    }

    @MainActor
    func acceptInvitation(from peer: MCPeerID) -> Bool {
        guard isHost, !hasStartedGame, players.count + pendingPeers.count < 4,
              !pendingPeers.contains(peer), !connectedPeers.contains(peer) else { return false }
        pendingPeers.insert(peer)
        let expectedSession = session
        invitationTasks[peer] = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(10)) } catch { return }
            guard let self, session === expectedSession else { return }
            if connectedPeers.contains(peer) {
                closeRoom(reason: "참가자 확인이 지연되어 연결을 종료했습니다. 방에 다시 참여해주세요.")
                return
            }
            pendingPeers.remove(peer)
            invitationTasks.removeValue(forKey: peer)
        }
        return true
    }

    @MainActor
    func peer(_ peer: MCPeerID, changedTo state: MCSessionState) {
        guard state != .connecting else { return }
        if state == .connected {
            if !connectedPeers.contains(peer) { connectedPeers.append(peer) }
            if isHost, !hasStartedGame { pendingPeers.insert(peer) }
            else if !isHost, peer == hostPeerID { _ = send(.hello(localDeviceID), to: [peer]) }
        } else if state == .notConnected {
            pendingPeers.remove(peer)
            invitationTasks.removeValue(forKey: peer)?.cancel()
            connectedPeers.removeAll { $0 == peer }
            peerDeviceIDs.removeValue(forKey: peer)
            if !isHost, hostPeerID == peer {
                closeRoom(reason: "방장과의 연결이 종료되었습니다.")
            } else if isHost, hasStartedGame, players.contains(where: { $0.peerID == peer }) {
                _ = send(.roomClosed)
                closeRoom(reason: "참가자의 연결이 종료되어 게임을 중단했습니다.")
            } else if isHost {
                players.removeAll { $0.peerID == peer }
                sendPlayersUpdate()
            }
        }
    }

    @MainActor
    func receive(_ data: Data, from peer: MCPeerID) {
        guard let message = try? JSONDecoder().decode(LobbyMessage.self, from: data) else { return }
        do {
            switch message {
            case .hello(let deviceID) where isHost && !hasStartedGame:
                guard session?.connectedPeers.contains(peer) == true || connectedPeers.contains(peer),
                      deviceID != localDeviceID,
                      !peerDeviceIDs.contains(where: { $0.key != peer && $0.value == deviceID }) else { return }
                if !connectedPeers.contains(peer) { connectedPeers.append(peer) }
                guard peerDeviceIDs[peer] == nil || peerDeviceIDs[peer] == deviceID else { return }
                peerDeviceIDs[peer] = deviceID
                pendingPeers.remove(peer)
                invitationTasks.removeValue(forKey: peer)?.cancel()
                if !players.contains(where: { $0.peerID == peer }) { appendPlayer(named: peer.displayName, peer: peer) }
                sendPlayersUpdate()
            case .players(let snapshots) where !isHost && peer == hostPeerID && !hasStartedGame:
                try apply(snapshots)
            case .addPlayer(let name) where isHost && connectedPeers.contains(peer) && !hasStartedGame:
                appendPlayer(named: name, peer: peer)
                sendPlayersUpdate()
            case .game(let message):
                guard let sender = peerDeviceIDs[peer], isHost || peer == hostPeerID else { return }
                let accepted = onGameMessage?(message, sender) == true
                if case .startGame = message, accepted, !isHost {
                    browser?.stopBrowsingForPeers()
                    hasStartedGame = true
                }
            case .roomClosed where !isHost && peer == hostPeerID:
                closeRoom(reason: "방장이 방을 나갔습니다.")
            default: break
            }
        } catch { report(error) }
    }

    @MainActor
    func sendPlayersUpdate() {
        guard isHost, !hasStartedGame else { return }
        do { _ = send(.players(try snapshots())) }
        catch { report(error) }
        startAdvertising()
    }

    @MainActor
    func report(_ error: Error) {
        connectionError = error.localizedDescription
        logger.error("대기실 연결 실패: \(error.localizedDescription)")
    }

    private func replaceSession() {
        let session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session
    }

    @MainActor
    private func configurePeerAndSession(with name: String) {
        disconnect()
        roomClosedReason = nil
        myPeerID = MCPeerID(displayName: name)
        replaceSession()
    }

    @MainActor
    private func appendPlayer(named name: String, peer: MCPeerID) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let occupied = Set(players.map(\.sequence))
        guard !name.isEmpty, players.count + pendingPeers.count < 4,
              let sequence = (1...4).first(where: { !occupied.contains($0) }) else { return }
        guard let deviceID = peer == myPeerID ? localDeviceID : peerDeviceIDs[peer] else { return }
        players.append(PlayerModel(name: name, sequence: sequence, peerID: peer, deviceID: deviceID, preparePieces: false))
        players.sort { $0.sequence < $1.sequence }
    }

    @MainActor
    private func snapshots() throws -> [LobbyPlayerSnapshot] {
        try players.map { player in
            LobbyPlayerSnapshot(id: player.id, name: player.name, sequence: player.sequence,
                                peerData: try NSKeyedArchiver.archivedData(withRootObject: player.peerID, requiringSecureCoding: true),
                                isHost: player.isHost, deviceID: player.deviceID)
        }
    }

    /// 검증·복원 전체가 성공한 뒤 한 번에 반영한다. 반복 명단 수신으로 기존 말 엔티티를 재생성하지 않는다.
    @MainActor
    private func apply(_ snapshots: [LobbyPlayerSnapshot]) throws {
        guard (2...4).contains(snapshots.count), Set(snapshots.map(\.id)).count == snapshots.count,
              Set(snapshots.map(\.sequence)).count == snapshots.count,
              snapshots.allSatisfy({ (1...4).contains($0.sequence) && !$0.name.isEmpty }),
              snapshots.filter(\.isHost).count == 1 else { throw LobbyError.invalidRoster }
        let entries = try snapshots.map { snapshot -> (LobbyPlayerSnapshot, MCPeerID) in
            guard let peer = try NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: snapshot.peerData) else { throw LobbyError.invalidRoster }
            return (snapshot, peer)
        }
        guard entries.contains(where: { $0.0.isHost && $0.1 == hostPeerID }),
              entries.contains(where: { $0.1 == myPeerID && $0.0.deviceID == localDeviceID }) else { throw LobbyError.invalidRoster }
        var deviceIDs: [MCPeerID: UUID] = [:]
        for (snapshot, peer) in entries {
            if let existing = deviceIDs[peer], existing != snapshot.deviceID { throw LobbyError.invalidRoster }
            guard !deviceIDs.contains(where: { $0.key != peer && $0.value == snapshot.deviceID }) else { throw LobbyError.invalidRoster }
            deviceIDs[peer] = snapshot.deviceID
        }
        peerDeviceIDs = deviceIDs
        players = entries.sorted { $0.0.sequence < $1.0.sequence }.map { snapshot, peer in
            if let existing = players.first(where: { $0.id == snapshot.id && $0.name == snapshot.name && $0.sequence == snapshot.sequence && $0.peerID == peer && $0.isHost == snapshot.isHost && $0.deviceID == snapshot.deviceID }) {
                return existing
            }
            return PlayerModel(id: snapshot.id, name: snapshot.name, sequence: snapshot.sequence, peerID: peer, isHost: snapshot.isHost,
                               deviceID: snapshot.deviceID, preparePieces: false)
        }
    }

    @MainActor
    @discardableResult
    private func send(_ message: LobbyMessage, to peers: [MCPeerID]? = nil) -> Bool {
        let peers = peers ?? connectedPeers
        guard !peers.isEmpty else { return true }
        guard let session else { return false }
        do {
            try session.send(JSONEncoder().encode(message), toPeers: peers, with: .reliable)
            connectionError = nil
            return true
        } catch {
            report(error)
            return false
        }
    }

    @MainActor
    private func closeRoom(reason: String) {
        disconnect()
        roomClosedReason = reason
    }
}
