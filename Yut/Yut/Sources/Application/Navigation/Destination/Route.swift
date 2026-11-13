//
//  Router.swift
//  YUT
//
//  Created by Hwnag Seyeon on 7/21/25.
//

enum Route: Hashable {
    case home
    case localPlay
    case hostNameInput
    case guestNameInput
    case roomList(String)
    case waitingRoom(RoomModel)
    case playView
    case winner
    case settings
    case legalDocument(LegalDocument.Kind)
    case creators
}
