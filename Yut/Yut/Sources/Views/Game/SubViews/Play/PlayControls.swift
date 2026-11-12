import SwiftUI

struct PlayControls: View {
    let state: GameState
    let canAct: Bool
    let isHost: Bool
    let colors: SurfaceColors?
    let usesManualThrow: Bool
    let showsHand: Bool
    let onStart: () -> Void
    let onGather: () -> Void
    let onThrow: () -> Void
    let onNewPiece: () -> Void
    let onCancelSelection: () -> Void

    var body: some View {
        VStack {
            switch state.phase {
            case .preparing:
                if !isHost { InstructionView(text: "방장이 게임을 시작할 때까지 기다려주세요", colors: colors) }
                Spacer()
                ActionButton(title: "윷놀이 시작!", isEnabled: isHost, size: .large, cornerRadius: 24, action: onStart).padding(.horizontal, 20)
            case .readyToThrow:
                InstructionView(text: canAct ? "버튼을 누르고 기기를 흔들어 윷을 던지세요" : "\(state.currentPlayer?.name ?? "플레이어")의 차례입니다", colors: colors)
                Spacer()
                if canAct {
                    YutThrowButton(sequence: (state.currentPlayer?.order ?? 0) + 1, action: onGather)
                        .accessibilityLabel("윷 모으기")
                }
            case .gathering: Spacer()
            case .waitingForShake:
                InstructionView(text: canAct ? (usesManualThrow ? "버튼을 눌러 윷을 던지세요" : "기기를 흔들어 윷을 던지세요") : "\(state.currentPlayer?.name ?? "플레이어")이 윷을 던지고 있습니다", colors: colors)
                Spacer()
                if canAct, usesManualThrow, showsHand { ActionButton(title: "윷 던지기", isEnabled: true, size: .large, cornerRadius: 24, action: onThrow).padding(.horizontal, 20) }
            case .throwing, .showingResult, .showingBonus: Spacer()
            case .selectingPiece:
                InstructionView(text: "\(state.currentPlayer?.name ?? "플레이어")의 턴: 움직일 말을 탭하세요.", colors: colors)
                Spacer()
                if state.canPlaceNewPiece, canAct { ActionButton(title: "새 말 놓기", isEnabled: true, size: .large, cornerRadius: 24, action: onNewPiece).padding(.horizontal, 20) }
            case .selectingDestination:
                InstructionView(text: "말을 옮길 곳을 선택하세요.", colors: colors)
                Spacer()
                if canAct { ActionButton(title: "말 다시 선택", isEnabled: true, size: .large, cornerRadius: 24, action: onCancelSelection).padding(.horizontal, 20) }
            case .promptingForCarry, .finished: Spacer()
            }
        }
    }
}
