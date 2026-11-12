import SwiftUI

struct GuestNameInputView: View {
    @StateObject private var viewModel: GuestNameInputViewModel

    init(viewModel: @autoclosure @escaping () -> GuestNameInputViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NameInputScreen(nickname: $viewModel.nickname, onSubmit: viewModel.submitNickname, onBack: viewModel.goBack)
    }
}
