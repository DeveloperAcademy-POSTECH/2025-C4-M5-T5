//
//  RoomModel.swift
//  YUT
//
//  Created by Hwnag Seyeon on 7/26/25.
//

import SwiftUI

struct RoomModel: Identifiable, Codable, Hashable {
    let id: UUID
    var roomName: String
    var hostName: String
    var maxPlayers: Int
    var players: [PlayerModel]
    var advertisedPlayerCount: Int?

    var currentPlayers: Int { advertisedPlayerCount ?? players.count }

    init(id: UUID = UUID(), roomName: String, hostName: String, maxPlayers: Int = 4, players: [PlayerModel] = [], advertisedPlayerCount: Int? = nil) {
        self.id = id
        self.roomName = roomName
        self.hostName = hostName
        self.maxPlayers = maxPlayers
        self.players = players
        self.advertisedPlayerCount = advertisedPlayerCount
    }
}
