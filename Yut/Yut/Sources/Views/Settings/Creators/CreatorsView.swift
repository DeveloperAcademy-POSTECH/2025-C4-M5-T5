import SwiftUI

struct CreatorsView: View {
    @ObservedObject private var viewModel: CreatorsViewModel

    init(viewModel: CreatorsViewModel) { self.viewModel = viewModel }

    var body: some View {
        ScrollView {
            CreatorsSection(names: viewModel.creators)
                .padding(32)
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(ThemeColors.canvas.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                IconButton(systemName: "chevron.left", accessibilityLabel: "뒤로", action: viewModel.goBack)
            }
        }
    }
}
