import SwiftUI

struct HostNameInputView: View {
    @StateObject private var viewModel: HostNameInputViewModel

    init(viewModel: @autoclosure @escaping () -> HostNameInputViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NameInputScreen(nickname: $viewModel.nickname, onSubmit: viewModel.submitNickname, onBack: viewModel.goBack)
    }
}
