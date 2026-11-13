import SwiftUI

struct LocalPlayerSlot: View {
    let piece: PieceType
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            if isSelected {
                PlayerCard(name: "플레이어 \(piece.sequence)", profileImage: "Player/P\(piece.sequence)/profile")
            } else {
                AddPlayerCard()
            }
        }
        .buttonStyle(LocalPlayerSlotButtonStyle())
        .accessibilityLabel("플레이어 \(piece.sequence) \(isSelected ? "삭제" : "추가")")
        .accessibilityHint(isSelected ? "다시 누르면 참가에서 빠집니다" : "누르면 참가합니다")
        .accessibilityIdentifier("localPlayerSlot\(piece.sequence)")
    }
}

/// 기본 버튼의 눌림 투명도 효과 없이 슬롯 내용만 교체한다.
private struct LocalPlayerSlotButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
    }
}
