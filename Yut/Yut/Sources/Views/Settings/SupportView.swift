import SwiftUI

struct SupportView: View {
    @StateObject private var viewModel: SupportViewModel

    init(viewModel: @autoclosure @escaping () -> SupportViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        Text("준비중")
            .font(Typography.body)
            .foregroundStyle(ThemeColors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ThemeColors.canvas.ignoresSafeArea())
            .navigationTitle("문의하기")
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
