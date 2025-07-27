struct Room: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let currentPlayers: Int
    let maxPlayers: Int
}
