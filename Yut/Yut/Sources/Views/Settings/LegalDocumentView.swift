import SwiftUI

struct LegalDocumentView: View {
    @StateObject private var viewModel: LegalDocumentViewModel

    init(viewModel: @autoclosure @escaping () -> LegalDocumentViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if let document = viewModel.document {
                    ForEach(document.sections) { section in LegalDocumentSectionView(section: section) }
                } else if let error = viewModel.errorMessage {
                    Text(error).font(Typography.body).foregroundStyle(ThemeColors.textPrimary)
                    ActionButton(title: "다시 시도") { Task { await viewModel.load() } }
                } else {
                    ProgressView("문서를 불러오고 있습니다")
                        .tint(ThemeColors.textPrimary).foregroundStyle(ThemeColors.textPrimary)
                }
            }
            .padding(24)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(ThemeColors.canvas.ignoresSafeArea())
        .navigationTitle(viewModel.kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(ThemeColors.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                IconButton(systemName: "chevron.left", accessibilityLabel: "뒤로", action: viewModel.goBack)
            }
        }
        .task { await viewModel.load() }
    }
}
