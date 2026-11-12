//
//  PlayerModel.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/17/25.
//
import RealityKit
import Foundation
import MultipeerConnectivity

class PlayerModel: Identifiable, ObservableObject, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let sequence: Int
    let peerID: MCPeerID
    let deviceID: UUID
    @Published var isHost: Bool

    var pieces: [PieceModel] = []
    
    static let fileNames = ["Piece1_yellow", "Piece2_jade", "Piece3_blue", "Piece4_red"]

    var object: String { "Player/P\(sequence)/object" }
    var profile: String { "Player/P\(sequence)/profile" }
    var button: String { "Player/P\(sequence)/buttoon" }
    var pieceEntity: String {
        switch sequence {
        case 1:
            return "Piece1_yellow"
        case 2:
            return "Piece2_jade"
        case 3:
            return "Piece3_blue"
        case 4:
            return "Piece4_red"
        default:
            fatalError("Invalid player sequence: \(sequence)")
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, sequence, isHost, peerDisplayName, peerData, deviceID
    }

    init(id: UUID = UUID(), name: String, sequence: Int, peerID: MCPeerID, isHost: Bool = false, deviceID: UUID? = nil, preparePieces: Bool = true) {
        self.id = id
        self.name = name
        self.sequence = sequence
        self.peerID = peerID
        self.deviceID = deviceID ?? id
        self.isHost = isHost

        for _ in 0..<(preparePieces ? 2 : 0) {
            guard let piece = PieceModel(owner: self) else { return }
            pieces.append(piece)
        }
    }

    required convenience init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let name = try container.decode(String.self, forKey: .name)
            let sequence = try container.decode(Int.self, forKey: .sequence)
            let isHost = try container.decode(Bool.self, forKey: .isHost)
            let peerDisplayName = try container.decode(String.self, forKey: .peerDisplayName)
            let id = try container.decode(UUID.self, forKey: .id)
            guard (1...4).contains(sequence) else {
                throw DecodingError.dataCorruptedError(forKey: .sequence, in: container, debugDescription: "플레이어 순서는 1~4여야 합니다.")
            }
            let peerID: MCPeerID
            if let data = try container.decodeIfPresent(Data.self, forKey: .peerData) {
                guard let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data) else {
                    throw DecodingError.dataCorruptedError(forKey: .peerData, in: container, debugDescription: "피어 식별자를 복원하지 못했습니다.")
                }
                peerID = decoded
            } else {
                // 기존 저장 데이터의 표시 이름은 복원하되, 실제 연결에는 탐색으로 받은 ID를 사용한다.
                peerID = MCPeerID(displayName: peerDisplayName)
            }
            self.init(id: id, name: name, sequence: sequence, peerID: peerID, isHost: isHost,
                      deviceID: try container.decodeIfPresent(UUID.self, forKey: .deviceID))
        }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(deviceID, forKey: .deviceID)
        try container.encode(name, forKey: .name)
        try container.encode(sequence, forKey: .sequence)
        try container.encode(isHost, forKey: .isHost)
        try container.encode(peerID.displayName, forKey: .peerDisplayName)
        try container.encode(NSKeyedArchiver.archivedData(withRootObject: peerID, requiringSecureCoding: true), forKey: .peerData)
    }

    static func == (lhs: PlayerModel, rhs: PlayerModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func load(name: String, sequence: Int, peerID: MCPeerID, isHost: Bool = false) async -> PlayerModel {
        return PlayerModel(name: name, sequence: sequence, peerID: peerID, isHost: isHost)
    }
}
