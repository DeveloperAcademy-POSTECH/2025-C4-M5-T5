import AVFoundation
import Combine
import UIKit

/// SwiftUI 화면의 재생성과 별개로 연결·게임·AR 객체의 수명을 한 번 조립한다.
@MainActor
final class AppDependencies: ObservableObject {
    let navigation = NavigationManager()
    let session: MPCManager
    let home: HomeViewModel
    let game: GameSessionController
    let waitingRoom: WaitingRoomViewModel
    let play: PlayViewModel
    let settings: SettingsViewModel
    let creators: CreatorsViewModel
    private let legalDocuments: any LegalDocumentLoading

    init() {
        let session = MPCManager.shared
        self.session = session
        let game = GameSessionController(transport: session)
        self.game = game
        let state = ARState(gameManager: GameManager())
        let scene = ARCoordinator(state: state, assets: AssetCacheManager(), sound: SoundService(audioSession: AVAudioSession.sharedInstance()))
        home = HomeViewModel(navigator: navigation)
        waitingRoom = WaitingRoomViewModel(session: session, navigator: navigation)
        play = PlayViewModel(game: game, scene: scene, models: { session.players }, navigator: navigation)
        settings = SettingsViewModel(navigator: navigation,
            supportActions: SystemSupportActions(application: .shared), supportChatURL: AppInformation.supportChatURL)
        creators = CreatorsViewModel(navigator: navigation)
        legalDocuments = BundledLegalDocumentLoader(bundle: .main)
    }

    func makeLocalPlayViewModel() -> LocalPlayViewModel {
        LocalPlayViewModel(session: session, navigator: navigation)
    }

    func makeLegalDocumentViewModel(_ kind: LegalDocument.Kind) -> LegalDocumentViewModel {
        LegalDocumentViewModel(kind: kind, loader: legalDocuments, navigator: navigation)
    }
}
