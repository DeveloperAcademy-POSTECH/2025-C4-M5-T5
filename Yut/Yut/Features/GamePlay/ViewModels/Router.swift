//
//  Router.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/21/25.
//

enum Route: Hashable {
    case home
    case hostNameInput
    case guestNameInput
    case roomList(String)
    case waitingRoom(RoomModel)
    case winner
}
