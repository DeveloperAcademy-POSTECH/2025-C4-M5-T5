import SwiftUI

struct PlayActionPanel: View {
    let phase: MatchPhase
    let canAct: Bool
    let canPlaceNewPiece: Bool
    let colors: SurfaceColors
    let usesManualThrow: Bool
    let showsHand: Bool
    let onGather: () -> Void
    let onThrow: () -> Void
    let onNewPiece: () -> Void
    let onCancelSelection: () -> Void

    private var instruction: String {
        switch phase {
        case .preparing:
            "게임을 준비하고 있습니다"
        case .readyToThrow:
            canAct ? "윷을 모아주세요" : "다른 플레이어의 던지기를 기다려주세요"
        case .waitingForShake:
            canAct ? (usesManualThrow ? "버튼을 눌러 윷을 던지세요" : "기기를 흔들어 윷을 던지세요") : "윷을 던지고 있습니다"
        case .throwing:
            "윷이 멈출 때까지 기다려주세요"
        case .selectingPiece:
            canAct ? "움직일 말을 선택하세요" : "말을 선택하고 있습니다"
        case .selectingDestination:
            canAct ? "말을 옮길 곳을 선택하세요" : "말을 옮길 곳을 선택하고 있습니다"
        case .choosingMoveResult:
            "이동 결과 선택을 기다리고 있습니다"
        case .movingPiece:
            "말을 이동하고 있습니다"
        case .gathering, .showingResult, .showingBonus, .finished:
            ""
        }
    }

    private var action: (title: String, perform: () -> Void)? {
        switch phase {
        case .readyToThrow where canAct: ("윷 모으기", onGather)
        case .waitingForShake where canAct && usesManualThrow && showsHand: ("윷 던지기", onThrow)
        case .selectingPiece where canAct && canPlaceNewPiece: ("새 말 놓기", onNewPiece)
        case .selectingDestination where canAct: ("말 다시 선택", onCancelSelection)
        default: nil
        }
    }

    var body: some View {
        ActionButton(title: action?.title ?? instruction, isEnabled: action != nil, colors: colors) {
            action?.perform()
        }
        .accessibilityIdentifier("playActionPanel")
        .transaction {
            $0.animation = nil
            $0.disablesAnimations = true
        }
    }
}
