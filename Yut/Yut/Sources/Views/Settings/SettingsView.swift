import SwiftUI

struct SettingsView: View {
    @ObservedObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) { self.viewModel = viewModel }

    var body: some View {
        ScrollView {
            SettingsMenuSection(onTerms: viewModel.showTerms, onPrivacyPolicy: viewModel.showPrivacyPolicy,
                onSupport: { Task { await viewModel.openSupport() } }, onCreators: viewModel.showCreators)
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
        .alert("문의하기 연결 안내", isPresented: $viewModel.isShowingSupportError) {
            Button("다시 시도") { Task { await viewModel.openSupport() } }
            Button("닫기", role: .cancel) {}
        } message: {
            Text("카카오 오픈채팅을 열지 못했습니다. 잠시 후 다시 시도해 주세요.")
        }
    }
}
