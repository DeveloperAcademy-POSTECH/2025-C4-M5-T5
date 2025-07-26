//
//  PlayerModel.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/17/25.
//

import Foundation
import MultipeerConnectivity

class PlayerModel: Identifiable, ObservableObject, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    var pieces: [PieceModel]
    let sequence: Int
    let peerID: MCPeerID

    @Published var isHost: Bool
    
    var object: String { "Player/P\(sequence)/object" }
    var profile: String { "Player/P\(sequence)/profile" }
    var buttonOn: String { "Player/P\(sequence)/button_on" }
    var buttonOff: String { "Player/P\(sequence)/button_off" }

    enum CodingKeys: String, CodingKey {
        case id, name, sequence, isHost, peerDisplayName
    }

    init(name: String, sequence: Int, peerID: MCPeerID, isHost: Bool = false) {
        self.id = UUID()
        self.name = name
        self.pieces = []
        self.sequence = sequence
        self.peerID = peerID
        self.isHost = isHost

        for _ in 0 ..< 2 {
            let piece = PieceModel(owner: self)
            pieces.append(piece)
        }
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let sequence = try container.decode(Int.self, forKey: .sequence)
        let isHost = try container.decode(Bool.self, forKey: .isHost)
        let peerDisplayName = try container.decode(String.self, forKey: .peerDisplayName)

        self.init(name: name, sequence: sequence, peerID: MCPeerID(displayName: peerDisplayName), isHost: isHost)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(sequence, forKey: .sequence)
        try container.encode(isHost, forKey: .isHost)
        try container.encode(peerID.displayName, forKey: .peerDisplayName)
    }
    static func == (lhs: PlayerModel, rhs: PlayerModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
