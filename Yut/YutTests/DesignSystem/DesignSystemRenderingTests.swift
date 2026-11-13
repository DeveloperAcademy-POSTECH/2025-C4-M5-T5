import Combine
import Foundation
import SwiftUI
import Testing
import UIKit
@testable import Yut

@MainActor
@Suite(.serialized)
struct DesignSystemRenderingTests {
    @Test(arguments: [ColorScheme.light, .dark])
    func renderPlayerOverlaysAndEmptyAndPopulatedRoomList(scheme: ColorScheme) async throws {
        let mode = scheme == .light ? "Light" : "Dark"
        for piece in PieceType.allCases {
            try save(PlayerOverlayGallery(piece: piece), scheme: scheme, name: "\(mode)-Player-\(piece.sequence)")
        }
        let source = GalleryRoomSession()
        let viewModel = RoomListViewModel(session: source, navigator: GalleryNavigation())
        try await saveHostedRoomList(viewModel, scheme: scheme, name: "\(mode)-RoomList-Empty")
        source.rooms.send([RoomModel(roomName: "친구", hostName: "친구", advertisedPlayerCount: 2)])
        for _ in 0..<100 {
            if !viewModel.rooms.isEmpty { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        try #require(viewModel.rooms.count == 1)
        try await saveHostedRoomList(viewModel, scheme: scheme, name: "\(mode)-RoomList-Populated")
    }
    @Test(arguments: [ColorScheme.light, .dark])
    func renderSharedControlsAndFeatureDialogs(scheme: ColorScheme) throws {
        let mode = scheme == .light ? "Light" : "Dark"
        try save(ComponentGallery(), scheme: scheme, name: "\(mode)-Components", height: 1120)
        try save(AppNoticeView(title: "연결 안내", message: "방장과의 연결이 종료되었습니다.",
            primaryTitle: "확인", onPrimary: {}), scheme: scheme, name: "\(mode)-ConnectionNotice")
        try save(GameEndedView(onHome: {}), scheme: scheme, name: "\(mode)-GameEnded")
        try save(MoveResultChoiceView(choices: [.init(id: 1, result: .yut), .init(id: 2, result: .mo)],
            colors: ThemeColors.playerYellow, onChoose: { _ in }, onCancel: {}), scheme: scheme, name: "\(mode)-MoveResultChoice")
        for isHost in [true, false] {
            try save(PlacementControls(phase: .scanning, area: 7, isHost: isHost,
                colors: ThemeColors.playerYellow, minimumArea: 15, isPreparing: false,
                onNext: {}, onConfirm: {}), scheme: scheme,
                name: "\(mode)-Scanning-\(isHost ? "Host" : "Guest")")
        }
        try save(PlacementControls(phase: .waitingForHost, area: 15, isHost: false,
            colors: ThemeColors.playerYellow, minimumArea: 15, isPreparing: false,
            onNext: {}, onConfirm: {}), scheme: scheme, name: "\(mode)-Scanning-GuestReady")
        for piece in PieceType.allCases {
            let game = try winnerGame(piece: piece)
            defer { game.stop() }
            try save(WinnerView(viewModel: WinnerViewModel(game: game)), scheme: scheme,
                name: "\(mode)-Winner-\(piece.sequence)")
        }
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func renderLocalPlayerSlotsOnSmallAndRegularScreens(scheme: ColorScheme) async throws {
        let mode = scheme == .light ? "Light" : "Dark"
        for width: CGFloat in [320, 402] {
            let model = LocalPlayViewModel(session: GalleryLocalSession(), navigator: GalleryNavigation())
            model.togglePlayer(slot: 3)
            model.togglePlayer(slot: 4)
            try await saveHosted(LocalPlayView(viewModel: model), scheme: scheme,
                name: "\(mode)-LocalPlay-\(Int(width))", width: width, height: width == 320 ? 568 : 874)
        }
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func renderStoredResultsAndPlayerProgress(scheme: ColorScheme) async throws {
        let players = (0..<4).map { GamePlayer(name: "플레이어\($0 + 1)", order: $0) }
        let positions: [[PiecePosition]] = [[.home, .onBoard(route: 0, index: 1)],
            [.onBoard(route: 0, index: 3), .finished], [.home, .home], [.finished, .home]]
        let pieces = players.enumerated().flatMap { index, player in
            positions[index].map { GamePiece(playerID: player.id, position: $0) }
        }
        var state = GameState(players: players, pieces: pieces)
        try state.apply(.startPlaying)
        for result: YutResult in [.yut, .mo, .gae] {
            for action: GameAction in [.beginThrow, .armThrow, .releaseThrow(launch: .testLaunch),
                                      .recordThrow(result), .dismissResult] { try state.apply(action) }
        }
        let progress = players.enumerated().map { index, player in
            PlayerPieceProgress(id: player.id, name: player.name, order: player.order,
                isCurrent: index == 0, isLocal: index == 0, positions: positions[index])
        }
        let content = PlayControls(state: state, canAct: true, playerProgress: progress,
            usesManualThrow: true, showsHand: false,
            onGather: {}, onThrow: {}, onNewPiece: {}, onCancelSelection: {})
            .background(ThemeColors.canvas)
        let mode = scheme == .light ? "Light" : "Dark"
        for width: CGFloat in [320, 402] {
            try await saveHosted(content, scheme: scheme, name: "\(mode)-GameProgress-\(Int(width))", width: width)
        }
        let observer = PlayControls(state: state, canAct: false, playerProgress: progress,
            usesManualThrow: false, showsHand: false,
            onGather: {}, onThrow: {}, onNewPiece: {}, onCancelSelection: {})
            .background(ThemeColors.canvas)
        try await saveHosted(observer, scheme: scheme, name: "\(mode)-GameProgress-Observer")
        for player in progress {
            try await saveHosted(PlayerProgressStrip(players: [player]), scheme: scheme,
                name: "\(mode)-Progress-Player-\(player.order)")
        }
        try await saveHosted(FinishActionView(colors: ThemeColors.playerBlue,
            position: { CGPoint(x: 260, y: 540) }, onFinish: {}).ignoresSafeArea(),
            scheme: scheme, name: "\(mode)-FinishAction")
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func selectedAndUnselectedChoicesKeepIdenticalSize(scheme: ColorScheme) throws {
        for title in ["윷", "빽도"] {
            let selected = ImageRenderer(content: ChoiceButton(title: title, isSelected: true,
                isEnabled: true, colors: ThemeColors.playerBlue, action: {}).environment(\.colorScheme, scheme))
            let unselected = ImageRenderer(content: ChoiceButton(title: title, isSelected: false,
                isEnabled: true, colors: ThemeColors.playerBlue, action: {}).environment(\.colorScheme, scheme))
            let selectedSize = try #require(selected.uiImage?.size)
            let unselectedSize = try #require(unselected.uiImage?.size)
            #expect(selectedSize == unselectedSize)
            #expect(selectedSize.width >= 44 && selectedSize.height >= 44)
        }
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func actionAndStatusPanelsKeepSameGeometry(scheme: ColorScheme) throws {
        let mode = scheme == .light ? "Light" : "Dark"
        var sizes: [CGSize] = []
        for phase: MatchPhase in [.readyToThrow, .throwing, .selectingPiece, .movingPiece] {
            let panel = PlayActionPanel(phase: phase, canAct: true, canPlaceNewPiece: false,
                colors: ThemeColors.playerJade, usesManualThrow: false, showsHand: false,
                onGather: {}, onThrow: {}, onNewPiece: {}, onCancelSelection: {})
            let renderer = ImageRenderer(content: panel.frame(width: 280).environment(\.colorScheme, scheme))
            sizes.append(try #require(renderer.uiImage?.size))
            try save(panel.padding(.horizontal, 20), scheme: scheme, name: "\(mode)-Action-\(phase.rawValue)", height: 100)
        }
        #expect(sizes.allSatisfy { $0 == CGSize(width: 280, height: 64) })
    }

    private func save<Content: View>(_ content: Content, scheme: ColorScheme, name: String, height: CGFloat = 874) throws {
        let renderer = ImageRenderer(content: content
            .frame(width: 402, height: height)
            .background(ThemeColors.canvas)
            .environment(\.colorScheme, scheme))
        renderer.scale = 2
        let data = try #require(renderer.uiImage?.pngData())
        let directory = try #require(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)
            .appendingPathComponent("DesignSystemQA")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: directory.appendingPathComponent(name + ".png"))
    }

    /// ScrollView의 실제 레이아웃은 ImageRenderer 대신 호스팅 윈도에서 확인한다.
    private func saveHostedRoomList(_ model: RoomListViewModel, scheme: ColorScheme, name: String) async throws {
        try await saveHosted(NavigationStack { RoomListView(viewModel: model) }, scheme: scheme, name: name)
    }

    private func saveHosted<Content: View>(_ content: Content, scheme: ColorScheme, name: String, width: CGFloat = 402, height: CGFloat = 874) async throws {
        let frame = CGRect(x: 0, y: 0, width: width, height: height)
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = frame
        window.overrideUserInterfaceStyle = scheme == .dark ? .dark : .light
        let controller = UIHostingController(rootView: content.environment(\.colorScheme, scheme))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        try await Task.sleep(for: .milliseconds(120))
        controller.view.layoutIfNeeded()
        let renderer = UIGraphicsImageRenderer(bounds: frame)
        let image = renderer.image { _ in controller.view.drawHierarchy(in: frame, afterScreenUpdates: true) }
        let data = try #require(image.pngData())
        let directory = try #require(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)
            .appendingPathComponent("DesignSystemQA")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: directory.appendingPathComponent(name + ".png"))
    }

    private func winnerGame(piece: PieceType) throws -> GameSessionController {
        let players = (0..<4).map { GamePlayer(name: "플레이어\($0 + 1)", order: $0) }
        let winner = players[piece.sequence - 1]
        let pieces = players.flatMap { player -> [GamePiece] in
            if player.id == winner.id {
                return [GamePiece(playerID: player.id, position: .onBoard(route: 0, index: GameBoard.routes[0].count - 1)),
                        GamePiece(playerID: player.id, position: .finished)]
            }
            return [GamePiece(playerID: player.id), GamePiece(playerID: player.id)]
        }
        var state = GameState(players: players, pieces: pieces, currentPlayerIndex: piece.sequence - 1)
        let initial = state
        for action: GameAction in [.startPlaying, .beginThrow, .armThrow, .releaseThrow(launch: .testLaunch), .recordThrow(.dho), .dismissResult] {
            try state.apply(action)
        }
        try state.apply(.selectPiece(try #require(state.currentPieces.first).id))
        try state.apply(.selectDestination(try #require(state.availableDestinations.first)))
        let transport = TestGameTransport(isHost: false, localDeviceID: players[0].deviceID,
            hostDeviceID: players[1].deviceID, players: players)
        let game = GameSessionController(transport: transport)
        try #require(game.receive(.startGame(initial), from: players[1].deviceID))
        try #require(game.receive(.state(state), from: players[1].deviceID))
        return game
    }
}

private struct PlayerOverlayGallery: View {
    let piece: PieceType
    var body: some View {
        VStack(spacing: 24) {
            Text("플레이어 \(piece.sequence)").font(Typography.screenTitle)
            InstructionView(text: "플레이어 \(piece.sequence)의 차례입니다", colors: piece.surfaceColors)
            ProgressBar(text: "말판을 배치할 평면을 스캔해 주세요", currentProgress: 7, minRequiredArea: 15,
                        colors: piece.surfaceColors)
            ProgressBar(text: "스캔이 완료되었습니다", currentProgress: 15, minRequiredArea: 15,
                        colors: piece.surfaceColors)
            YutResultDisplay(result: .geol, colors: piece.surfaceColors)
        }
    }
}

@MainActor
private final class GalleryRoomSession: LobbySessionManaging {
    let rooms = CurrentValueSubject<[RoomModel], Never>([])
    var availableRoomsPublisher: AnyPublisher<[RoomModel], Never> { rooms.eraseToAnyPublisher() }
    func hostRoom(named nickname: String) -> RoomModel? { nil }
    func browseRooms(as nickname: String) {}
    func connect(to room: RoomModel) -> Bool { false }
    func disconnect() {}
}

@MainActor
private final class GalleryNavigation: NameInputNavigating, WaitingRoomNavigating {
    func showGame() {}
    func returnHome() {}
    func showWaitingRoom(_ room: RoomModel) {}
    func showRoomList(as nickname: String) {}
    func goBack() {}
}

private struct ComponentGallery: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("공용 컴포넌트").font(Typography.screenTitle).foregroundStyle(ThemeColors.textPrimary)
            ActionButton(title: "윷놀이 시작하기") {}
            ActionButton(title: "인원 모으는 중...", isEnabled: false) {}
            ActionButton(title: "방 만들기", variant: .secondary) {}
            HStack {
                ActionButton(title: "추가", size: .compact) {}
                ActionButton(title: "추가", isEnabled: false, size: .compact) {}
            }
            InstructionView(text: "말판의 크기와 위치를 조정하세요")
            ProgressBar(text: "말판을 배치할 평면을 충분히 스캔해 주세요", currentProgress: 7, minRequiredArea: 15)
            YutResultDisplay(result: .backdho).scaleEffect(0.5).frame(height: 160)
            HStack(spacing: 16) {
                PlayerCard(name: "플레이어", profileImage: "Player/P1/profile")
                AddPlayerCard()
            }
        }
        .padding(20)
    }
}

@MainActor
private final class GalleryLocalSession: LocalPlaySessionManaging {
    func startLocalGame(slots: Set<Int>) -> Bool { true }
}
