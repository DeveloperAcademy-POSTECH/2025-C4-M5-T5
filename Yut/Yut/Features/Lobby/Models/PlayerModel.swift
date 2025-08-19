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
    @Published var isHost: Bool

    var pieces: [PieceModel] = []
//    var pieceEntities: [Entity] = []
    
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
        /*"Player/P\(sequence)/token"*/
    }

    enum CodingKeys: String, CodingKey {
        case id, name, sequence, isHost, peerDisplayName
    }

    init(name: String, sequence: Int, peerID: MCPeerID, isHost: Bool = false) {
        self.id = UUID()
        self.name = name
        self.sequence = sequence
        self.peerID = peerID
        self.isHost = isHost
//        self.pieceEntities = entities
//
//                let dummyEntities = Array(repeating: Entity(), count: 4)
//                self.pieceEntities = dummyEntities

        for _ in 0..<2 {
            guard let piece = PieceModel(owner: self) else { return }
//            let piece = PieceModel(owner: self, entity: dummyEntities[i])
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

            // Entity 임의로 주입
            let dummyEntities = Array(repeating: Entity(), count: 4)
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

    static func load(name: String, sequence: Int, peerID: MCPeerID, isHost: Bool = false) async -> PlayerModel {
//        var loadedEntities: [Entity] = []

//        for file in fileNames {
//            do {
//                let entity = try await Entity(named: file)
//                loadedEntities.append(entity)
//            } catch {
//                print("'\(file)' 로딩 실패:", error)
//            }
//        }

        return PlayerModel(name: name, sequence: sequence, peerID: peerID, isHost: isHost)
    }
}
