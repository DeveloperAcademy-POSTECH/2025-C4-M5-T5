import SwiftUI

struct CreatorsView: View {
    @ObservedObject private var viewModel: CreatorsViewModel

    init(viewModel: CreatorsViewModel) { self.viewModel = viewModel }

    var body: some View {
        ScrollView {
            CreatorsSection(names: viewModel.creators)
                .padding(24)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
        }
        .background(ThemeColors.canvas.ignoresSafeArea())
        .navigationTitle("제작자")
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
