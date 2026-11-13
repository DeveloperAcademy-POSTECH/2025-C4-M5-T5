import SwiftUI

/// 같은 지점에 서로 다른 결과로 갈 수 있을 때만 소비할 결과를 확인한다.
struct MoveResultChoiceView: View {
    let choices: [StoredYutResult]
    let colors: SurfaceColors?
    let onChoose: (Int) -> Void
    let onCancel: () -> Void

    var body: some View {
        ModalPanel {
            VStack(spacing: 12) {
                Text("이 지점에 사용할 결과를 선택하세요")
                    .font(Typography.dialogTitle)
                    .multilineTextAlignment(.center)
                ForEach(choices) { choice in
                    ActionButton(title: "\(choice.result.displayText) 사용", size: .compact, colors: colors) {
                        onChoose(choice.id)
                    }
                }
                ActionButton(title: "취소", variant: .secondary, size: .compact, action: onCancel)
            }
        }
        .accessibilityIdentifier("moveResultChoice")
    }
}
