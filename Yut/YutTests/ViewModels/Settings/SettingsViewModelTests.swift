import Foundation
import Testing
@testable import Yut

@MainActor
struct SettingsViewModelTests {
    @Test
    func settingsRoutesDocumentsSupportAndCreators() {
        let navigation = RecordingSettingsNavigation()
        let model = SettingsViewModel(navigator: navigation)
        model.showTerms()
        model.showPrivacyPolicy()
        model.showSupport()
        model.showCreators()
        model.goBack()
        #expect(navigation.documents == [.termsOfService, .privacyPolicy])
        #expect(navigation.supportCount == 1)
        #expect(navigation.creatorsCount == 1)
        #expect(navigation.backCount == 1)
        let creators = CreatorsViewModel(navigator: navigation)
        #expect(creators.creators == ["장성태", "이윤서", "박승은", "소연수", "황세연"])
        creators.goBack()
        #expect(navigation.backCount == 2)
    }

    @Test(arguments: [nil, "", " \n "] as [String?])
    func missingContactNeverOpensMailOrCopiesAnAddress(email: String?) async {
        let actions = RecordingSupportActions()
        let model = SupportViewModel(email: email, appVersion: "1.0", actions: actions, navigator: RecordingSettingsNavigation())
        #expect(!model.canContact)
        await model.composeEmail()
        model.copyEmail()
        #expect(actions.addresses.isEmpty)
        #expect(actions.copies.isEmpty)
        #expect(model.notice == nil)
        #expect(!model.isOpeningEmail)
    }

    @Test
    func unavailableMailOffersCopyAndSuccessfulMailClearsNotice() async {
        let actions = RecordingSupportActions()
        let model = SupportViewModel(email: " support@example.invalid \n", appVersion: "1.2", actions: actions,
            navigator: RecordingSettingsNavigation())
        await model.composeEmail()
        #expect(actions.addresses == ["support@example.invalid"])
        #expect(actions.bodies.first?.contains("1.2") == true)
        #expect(model.notice?.contains("복사") == true)
        #expect(!model.isOpeningEmail)
        model.copyEmail()
        #expect(actions.copies == ["support@example.invalid"])
        actions.canOpen = true
        await model.composeEmail()
        #expect(model.notice == nil)
    }

    @Test
    func bundledDocumentsAreAvailableOfflineAndDescribeYutPeerSharing() async throws {
        let loader = BundledLegalDocumentLoader(bundle: .main)
        let terms = try await loader.load(.termsOfService)
        let privacy = try await loader.load(.privacyPolicy)
        #expect(terms.sections.contains { $0.title == "제3조 안전한 AR 이용" })
        #expect(privacy.sections.contains { $0.title == "제2조 주변 기기와 공유되는 정보" })
        for document in [terms, privacy] {
            let body = document.sections.flatMap(\.paragraphs).joined(separator: "\n")
            #expect(body.contains("시행일: 미정"))
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
    var supportCount = 0
    var creatorsCount = 0
    var backCount = 0
    func showLegalDocument(_ kind: LegalDocument.Kind) { documents.append(kind) }
    func showSupport() { supportCount += 1 }
    func showCreators() { creatorsCount += 1 }
    func goBack() { backCount += 1 }
}

@MainActor
private final class RecordingSupportActions: SupportActions {
    var addresses: [String] = []
    var copies: [String] = []
    var bodies: [String] = []
    var canOpen = false
    func openEmail(to address: String, subject: String, body: String) async -> Bool {
        addresses.append(address)
        bodies.append(body)
        return canOpen
    }
    func copyEmail(_ address: String) { copies.append(address) }
}

private actor RetryLegalLoader: LegalDocumentLoading {
    private(set) var attempts = 0
    func load(_ kind: LegalDocument.Kind) throws -> LegalDocument {
        attempts += 1
        if attempts == 1 { throw CocoaError(.fileReadNoSuchFile) }
        return LegalDocument(markdown: "# 개인정보처리방침\n\n시행일: 미정\n\n## 개인정보 안내\n\n문의처 미등록")
    }
}
