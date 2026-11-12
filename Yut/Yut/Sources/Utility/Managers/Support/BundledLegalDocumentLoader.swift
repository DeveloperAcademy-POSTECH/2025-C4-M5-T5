import Foundation

/// 문서 읽기를 화면 생성과 메인 액터에서 분리한다.
actor BundledLegalDocumentLoader: LegalDocumentLoading {
    enum Failure: LocalizedError {
        case missingDocument
        var errorDescription: String? { "문서를 불러오지 못했습니다. 다시 시도해주세요." }
    }

    private let bundle: Bundle

    init(bundle: Bundle) { self.bundle = bundle }

    func load(_ kind: LegalDocument.Kind) throws -> LegalDocument {
        guard let url = bundle.url(forResource: kind.rawValue, withExtension: "md", subdirectory: "Legal")
            ?? bundle.url(forResource: kind.rawValue, withExtension: "md") else { throw Failure.missingDocument }
        let text = try String(contentsOf: url, encoding: .utf8)
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw Failure.missingDocument }
        return LegalDocument(markdown: text)
    }
}
