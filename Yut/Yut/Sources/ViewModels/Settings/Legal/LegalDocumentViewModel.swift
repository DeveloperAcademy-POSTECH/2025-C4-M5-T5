import Combine
import Foundation

@MainActor
final class LegalDocumentViewModel: ObservableObject {
    @Published private(set) var document: LegalDocument?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    let kind: LegalDocument.Kind
    private let loader: any LegalDocumentLoading
    private let navigator: any SettingsNavigating

    init(kind: LegalDocument.Kind, loader: any LegalDocumentLoading, navigator: any SettingsNavigating) {
        self.kind = kind
        self.loader = loader
        self.navigator = navigator
    }

    func load() async {
        guard document == nil, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let loaded = try await loader.load(kind)
            try Task.checkCancellation()
            document = loaded
        } catch is CancellationError { return }
        catch { errorMessage = "문서를 불러오지 못했습니다. 다시 시도해주세요." }
    }

    func goBack() { navigator.goBack() }
}
