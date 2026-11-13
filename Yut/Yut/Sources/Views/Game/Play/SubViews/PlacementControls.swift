import SwiftUI

struct PlacementControls: View {
    let phase: BoardPlacementPhase
    let area: Float
    let isHost: Bool
    let colors: SurfaceColors?
    let minimumArea: Float
    let isPreparing: Bool
    let onNext: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack {
            switch phase {
            case .loading:
                DecoratedBackground { InstructionView(text: "카메라가 켜지고 윷놀이가 시작됩니다!", colors: colors) }
            case .scanning:
                ProgressBar(text: "주변 공간을 스캔해주세요", currentProgress: area, minRequiredArea: minimumArea, colors: colors)
                Spacer()
                if isHost {
                    ActionButton(title: "다음", isEnabled: area >= minimumArea, size: .large, cornerRadius: 24, action: onNext).padding(.horizontal, 20)
                }
            case .placing:
                InstructionView(text: "탭해서 말판을 배치하세요", colors: colors)
                Spacer()
            case .adjusting:
                InstructionView(text: isPreparing ? "말판을 공유하고 있습니다" : "말판의 크기와 위치를 조정하세요", colors: colors)
                Spacer()
                if isHost {
                    ActionButton(title: "배치하기", isEnabled: !isPreparing, size: .large, cornerRadius: 24, action: onConfirm).padding(.horizontal, 20)
                }
            case .waitingForHost:
                InstructionView(text: "방장이 말판을 배치 중입니다", colors: colors)
                Spacer()
            case .relocalizing:
                InstructionView(text: "같은 공간을 비추며 말판을 찾고 있습니다", colors: colors)
                Spacer()
            case .confirmed: EmptyView()
            }
        }
    }
}
