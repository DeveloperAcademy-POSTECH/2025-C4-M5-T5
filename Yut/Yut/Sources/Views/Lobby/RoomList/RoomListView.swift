import SwiftUI

struct RoomListView: View {
    @StateObject private var viewModel: RoomListViewModel

    init(viewModel: @autoclosure @escaping () -> RoomListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.rooms) { room in
                    Button { viewModel.selectRoom(room) } label: { RoomRowView(room: room) }
                        .buttonStyle(.plain)
                }
                .padding(.bottom, 12)
            }
            .padding(.top, 40)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ThemeColors.canvas.ignoresSafeArea())
        .gesture(DragGesture().onEnded { value in if value.translation.width > 80 { viewModel.goBack() } })
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ThemeColors.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                IconButton(systemName: "chevron.left", accessibilityLabel: "뒤로", action: viewModel.goBack)
            }
            ToolbarItem(placement: .principal) {
                Text("주변 윷놀이방 참여하기")
                    .font(Typography.button)
                    .foregroundStyle(ThemeColors.textSecondary)
            }
        }
    }
}
