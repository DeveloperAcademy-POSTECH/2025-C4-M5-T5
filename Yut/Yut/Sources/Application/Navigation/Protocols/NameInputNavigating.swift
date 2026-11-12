@MainActor
protocol NameInputNavigating: AnyObject {
    func showWaitingRoom(_ room: RoomModel)
    func showRoomList(as nickname: String)
    func goBack()
}

extension NavigationManager: NameInputNavigating {
    func showWaitingRoom(_ room: RoomModel) { push(.waitingRoom(room)) }
    func showRoomList(as nickname: String) { push(.roomList(nickname)) }
    func goBack() { pop() }
}

