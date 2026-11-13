import SwiftUI

struct LocalPlayView: View {
    @StateObject private var viewModel: LocalPlayViewModel

    init(viewModel: LocalPlayViewModel) { _viewModel = StateObject(wrappedValue: viewModel) }

    var body: some View {
        WaitingRoomLayout(title: "한 기기로 플레이", leaveAccessibilityLabel: "돌아가기",
            buttonTitle: viewModel.buttonTitle, canStart: viewModel.canStart,
            onLeave: viewModel.goBack, onStart: viewModel.startGame) {
                ForEach(PieceType.allCases, id: \.sequence) { piece in
                    LocalPlayerSlot(piece: piece, isSelected: viewModel.selectedSlots.contains(piece.sequence)) {
                        viewModel.togglePlayer(slot: piece.sequence)
                    }
                }
            }
            .transaction { transaction in
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
            .overlay {
                if let error = viewModel.errorMessage {
                    AppNoticeView(title: "게임 안내", message: error, primaryTitle: "확인", onPrimary: viewModel.dismissError)
                }
            }
            .navigationBarBackButtonHidden(true)
    }
}
