@MainActor
protocol SettingsNavigating: AnyObject {
    func showLegalDocument(_ kind: LegalDocument.Kind)
    func showSupport()
    func showCreators()
    func goBack()
}

extension NavigationManager: SettingsNavigating {
    func showLegalDocument(_ kind: LegalDocument.Kind) { push(.legalDocument(kind)) }
    func showSupport() { push(.support) }
    func showCreators() { push(.creators) }
}
