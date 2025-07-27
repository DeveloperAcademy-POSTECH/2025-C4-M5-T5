//
//  RoomModel.swift
//  Yut
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

    var currentPlayers: Int { players.count }

    init(roomName: String, hostName: String, maxPlayers: Int = 4, players: [PlayerModel] = []) {
        self.id = UUID()
        self.roomName = roomName
        self.hostName = hostName
        self.maxPlayers = maxPlayers
        self.players = players
    }
}
