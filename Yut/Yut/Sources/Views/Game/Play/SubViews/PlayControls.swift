import SwiftUI

struct PlayControls: View {
    let state: GameState
    let canAct: Bool
    let playerProgress: [PlayerPieceProgress]
    let usesManualThrow: Bool
    let showsHand: Bool
    let onGather: () -> Void
    let onThrow: () -> Void
    let onNewPiece: () -> Void
    let onCancelSelection: () -> Void

    private var colors: SurfaceColors {
        PieceType.from(sequence: (state.currentPlayer?.order ?? 0) + 1)?.surfaceColors ?? ThemeColors.playerYellow
    }

    private var hidesProgress: Bool { [.gathering, .waitingForShake, .finished].contains(state.phase) }

    var body: some View {
        VStack(spacing: 12) {
            PlayerProgressStrip(players: playerProgress)
                .opacity(hidesProgress ? 0 : 1)
                .allowsHitTesting(!hidesProgress)
                .accessibilityHidden(hidesProgress)
            Spacer(minLength: 16)
            if state.isSelectingMove, !state.pendingResults.isEmpty {
                StoredResultsView(results: state.pendingResults, colors: colors)
                    .padding(.horizontal, 20)
            }
            if ![.gathering, .showingResult, .showingBonus, .finished].contains(state.phase) {
                PlayActionPanel(phase: state.phase, canAct: canAct,
                    canPlaceNewPiece: state.canPlaceNewPiece, colors: colors,
                    usesManualThrow: usesManualThrow, showsHand: showsHand,
                    onGather: onGather, onThrow: onThrow,
                    onNewPiece: onNewPiece, onCancelSelection: onCancelSelection)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 12)
        .transaction {
            $0.animation = nil
            $0.disablesAnimations = true
        }
    }
}
