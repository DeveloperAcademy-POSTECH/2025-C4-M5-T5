import Foundation
import Testing
@testable import Yut

@MainActor
struct SettingsViewModelTests {
    @Test
    func settingsRoutesDocumentsAndCreators() {
        let navigation = RecordingSettingsNavigation()
        let model = SettingsViewModel(navigator: navigation, supportActions: RecordingSupportActions(),
            supportChatURL: AppInformation.supportChatURL)
        model.showTerms()
        model.showPrivacyPolicy()
        model.showCreators()
        model.goBack()
        #expect(navigation.documents == [.termsOfService, .privacyPolicy])
        #expect(navigation.creatorsCount == 1)
        #expect(navigation.backCount == 1)
        let creators = CreatorsViewModel(navigator: navigation)
        #expect(creators.creators == ["장성태", "이윤서", "소연수", "박승은", "황세연"])
        creators.goBack()
        #expect(navigation.backCount == 2)
    }

    @Test
    func supportOpensConfiguredKakaoChatAndCanRetryFailure() async {
        let actions = RecordingSupportActions()
        let navigation = RecordingSettingsNavigation()
        let model = SettingsViewModel(navigator: navigation, supportActions: actions,
            supportChatURL: AppInformation.supportChatURL)
        await model.openSupport()
        #expect(actions.urls.map(\.absoluteString) == ["https://open.kakao.com/o/sgoSTQWi"])
        #expect(model.isShowingSupportError)
        #expect(!model.isOpeningSupport)
        #expect(navigation.documents.isEmpty)
        actions.canOpen = true
        await model.openSupport()
        #expect(actions.urls.count == 2)
        #expect(!model.isShowingSupportError)
        #expect(!model.isOpeningSupport)
    }

    @Test
    func missingChatAddressShowsFailureWithoutOpeningExternalApp() async {
        let actions = RecordingSupportActions()
        let model = SettingsViewModel(navigator: RecordingSettingsNavigation(), supportActions: actions,
            supportChatURL: nil)
        await model.openSupport()
        #expect(actions.urls.isEmpty)
        #expect(model.isShowingSupportError)
        #expect(!model.isOpeningSupport)
    }

    @Test
    func repeatedSupportTapWhileOpeningDoesNotOpenChatTwice() async {
        let actions = RecordingSupportActions()
        actions.canOpen = true
        let model = SettingsViewModel(navigator: RecordingSettingsNavigation(), supportActions: actions,
            supportChatURL: AppInformation.supportChatURL)
        actions.onOpen = {
            #expect(model.isOpeningSupport)
            await model.openSupport()
        }
        await model.openSupport()
        #expect(actions.urls.count == 1)
        #expect(!model.isOpeningSupport)
        #expect(!model.isShowingSupportError)
    }

    @Test
    func bundledDocumentsAreAvailableOfflineAndDescribeYutPeerSharing() async throws {
        #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String == "YUT")
        #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String == "YUT")
        let loader = BundledLegalDocumentLoader(bundle: .main)
        let terms = try await loader.load(.termsOfService)
        let privacy = try await loader.load(.privacyPolicy)
        #expect(terms.sections.contains { $0.title == "제3조 안전한 AR 이용" })
        #expect(privacy.sections.contains { $0.title == "제2조 주변 기기와 공유되는 정보" })
        for document in [terms, privacy] {
            let body = document.sections.flatMap(\.paragraphs).joined(separator: "\n")
            #expect(body.contains("윷(YUT)"))
            #expect(!body.contains("윷(Yut)"))
            #expect(body.contains("시행일: 2026년 11월 13일"))
            #expect(!body.contains("시행일: 미정"))
            #expect(!body.contains("초안"))
            #expect(!body.contains("작성일:"))
            #expect(body.contains("https://open.kakao.com/o/sgoSTQWi"))
            #expect(!body.contains("문의 이메일"))
            #expect(!body.contains("PawCut"))
            #expect(!body.contains("작성·게시 참고"))
        }
    }

    @Test
    func documentLoadFailureCanBeRetriedAndLoadedDocumentIsKept() async throws {
        let loader = RetryLegalLoader()
        let model = LegalDocumentViewModel(kind: .privacyPolicy, loader: loader, navigator: RecordingSettingsNavigation())
        await model.load()
        #expect(model.document == nil)
        #expect(model.errorMessage != nil)
        #expect(!model.isLoading)
        await model.load()
        #expect(model.document?.sections.last?.title == "개인정보 안내")
        #expect(model.errorMessage == nil)
        await model.load()
        #expect(await loader.attempts == 2)
    }
}

@MainActor
private final class RecordingSettingsNavigation: SettingsNavigating {
    var documents: [LegalDocument.Kind] = []
    var creatorsCount = 0
    var backCount = 0
    func showLegalDocument(_ kind: LegalDocument.Kind) { documents.append(kind) }
    func showCreators() { creatorsCount += 1 }
    func goBack() { backCount += 1 }
}

@MainActor
private final class RecordingSupportActions: SupportActions {
    var urls: [URL] = []
    var canOpen = false
    var onOpen: (() async -> Void)?

    func openChat(at url: URL) async -> Bool {
        urls.append(url)
        let handler = onOpen
        onOpen = nil
        await handler?()
        return canOpen
    }
}

private actor RetryLegalLoader: LegalDocumentLoading {
    private(set) var attempts = 0
    func load(_ kind: LegalDocument.Kind) throws -> LegalDocument {
        attempts += 1
        if attempts == 1 { throw CocoaError(.fileReadNoSuchFile) }
        return LegalDocument(markdown: "# 개인정보처리방침\n\n시행일: 미정\n\n## 개인정보 안내\n\n문의처 미등록")
    }
}
