import SwiftUI

/// 방 생성·참여의 공통 입력 화면이며 내비게이션 결정은 각 ViewModel에 남긴다.
struct NameInputScreen: View {
    @Binding var nickname: String
    let onSubmit: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            ThemeColors.canvas.ignoresSafeArea().onTapGesture { endTextEditing() }
            NameInputFormView(nickname: $nickname, title: "닉네임을 입력해주세요", onSubmit: onSubmit, autoFocus: true)
        }
        .gesture(DragGesture().onEnded { value in if value.translation.width > 80 { onBack() } })
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                IconButton(systemName: "chevron.left", accessibilityLabel: "뒤로", action: onBack)
            }
        }
    }
}
