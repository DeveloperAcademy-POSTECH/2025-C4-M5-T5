//
//  Router.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/21/25.
//

enum Route: Hashable {
    case home
    case hostNameInput
    case roomList
    case waitingRoom(Room)
    case winner
}
