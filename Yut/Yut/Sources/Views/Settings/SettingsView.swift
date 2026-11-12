import SwiftUI

struct SettingsView: View {
    @ObservedObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) { self.viewModel = viewModel }

    var body: some View {
        ScrollView {
            SettingsMenuSection(onTerms: viewModel.showTerms, onPrivacyPolicy: viewModel.showPrivacyPolicy,
                onSupport: viewModel.showSupport, onCreators: viewModel.showCreators)
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(ThemeColors.canvas.ignoresSafeArea())
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(ThemeColors.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                IconButton(systemName: "chevron.left", accessibilityLabel: "뒤로", action: viewModel.goBack)
            }
        }
    }
}
