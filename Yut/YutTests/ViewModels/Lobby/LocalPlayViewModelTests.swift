import Testing
@testable import Yut

@MainActor
struct LocalPlayViewModelTests {
    @Test
    func slotsToggleIndependentlyAndOnlyTwoToFourCanStart() {
        let session = LocalSession()
        let navigation = LocalNavigation()
        let model = LocalPlayViewModel(session: session, navigator: navigation)
        #expect(model.selectedSlots == [1, 2])
        model.togglePlayer(slot: 1)
        #expect(!model.canStart)
        model.startGame()
        #expect(session.requests.isEmpty)
        model.togglePlayer(slot: 4)
        model.togglePlayer(slot: 0)
        model.togglePlayer(slot: 5)
        #expect(model.selectedSlots == [2, 4])
        #expect(model.canStart)
        model.togglePlayer(slot: 4)
        #expect(model.selectedSlots == [2])
        model.togglePlayer(slot: 2)
        #expect(model.selectedSlots.isEmpty)
        #expect(!model.canStart)
        for slot in 1...4 { model.togglePlayer(slot: slot) }
        model.startGame()
        model.startGame()
        model.togglePlayer(slot: 1)
        #expect(session.requests == [[1, 2, 3, 4]])
        #expect(model.selectedSlots.count == 4)
        #expect(!model.canStart)
    }

    @Test
    func failureKeepsSelectionAndAllowsRetryAndBackReturnsHome() {
        let session = LocalSession()
        let navigation = LocalNavigation()
        let model = LocalPlayViewModel(session: session, navigator: navigation)
        session.succeeds = false
        model.startGame()
        #expect(model.canStart)
        #expect(model.errorMessage != nil)
        #expect(model.selectedSlots == [1, 2])
        session.succeeds = true
        model.startGame()
        #expect(model.hasStarted)
        #expect(session.requests.count == 2)
        model.goBack()
        #expect(navigation.homeCount == 1)
    }
}

@MainActor
private final class LocalSession: LocalPlaySessionManaging {
    var succeeds = true
    var requests: [Set<Int>] = []
    func startLocalGame(slots: Set<Int>) -> Bool { requests.append(slots); return succeeds }
}

@MainActor
private final class LocalNavigation: WaitingRoomNavigating {
    var homeCount = 0
    func showGame() {}
    func returnHome() { homeCount += 1 }
}
