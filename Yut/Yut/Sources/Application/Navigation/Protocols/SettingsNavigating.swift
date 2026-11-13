@MainActor
protocol SettingsNavigating: AnyObject {
    func showLegalDocument(_ kind: LegalDocument.Kind)
    func showCreators()
    func goBack()
}

extension NavigationManager: SettingsNavigating {
    func showLegalDocument(_ kind: LegalDocument.Kind) { push(.legalDocument(kind)) }
    func showCreators() { push(.creators) }
}
