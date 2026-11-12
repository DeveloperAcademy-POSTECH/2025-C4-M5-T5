protocol LegalDocumentLoading: Sendable {
    func load(_ kind: LegalDocument.Kind) async throws -> LegalDocument
}
