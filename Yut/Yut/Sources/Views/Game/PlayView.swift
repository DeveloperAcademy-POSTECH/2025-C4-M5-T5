import SwiftUI

struct PlayView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var viewModel: PlayViewModel
    @ObservedObject private var arState: ARState
    @State private var isAnimationDone = false

    init(viewModel: PlayViewModel) {
        self.viewModel = viewModel
        arState = viewModel.scene.arState
    }

    var body: some View {
        ZStack {
            if viewModel.match == nil {
                GameEndedView(onHome: viewModel.returnHomeIfEnded)
            }
            if viewModel.match != nil {
                ARViewContainer(scene: viewModel.scene).ignoresSafeArea()
            }
            if viewModel.match?.phase == .showingResult || viewModel.match?.phase == .showingBonus {
                VStack {
                    Spacer()
                    YutResultDisplay(result: viewModel.match?.phase == .showingBonus ? nil : viewModel.match?.latestResult,
                                     colors: viewModel.resultPieceType?.surfaceColors)
                        .frame(width: 300, height: 300)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
                .zIndex(1)
            }
            if viewModel.match?.phase == .gathering {
                YutGatheringSequenceView(frames: viewModel.scene.gatheringFrames, isAnimationDone: $isAnimationDone)
                    .ignoresSafeArea().transition(.opacity).zIndex(3).padding(.top, 40)
                    .allowsHitTesting(false)
            }
            if arState.showFinalFrame, let handImage = viewModel.scene.gatheringFrames.lastFrame {
                GeometryReader { geometry in
                    Image(uiImage: handImage).resizable().scaledToFill()
                        .frame(width: geometry.size.width + 60, height: geometry.size.height + 60)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .ignoresSafeArea().zIndex(2).padding(.top, 38)
                }
                .allowsHitTesting(false)
            }
            if arState.placementPhase == .confirmed, let state = viewModel.match {
                PlayControls(state: state, canAct: viewModel.canAct, isHost: viewModel.isHost,
                    colors: viewModel.turnPieceType?.surfaceColors,
                    usesManualThrow: arState.usesManualThrow, showsHand: arState.showFinalFrame,
                    onStart: viewModel.startPlaying, onGather: viewModel.beginThrow, onThrow: viewModel.throwManually,
                    onNewPiece: viewModel.placeNewPiece, onCancelSelection: viewModel.cancelSelection)
            } else if viewModel.match != nil {
                PlacementControls(phase: viewModel.placementControlsPhase, area: arState.recognizedArea,
                    isHost: viewModel.isHost,
                    colors: viewModel.scanningPieceType?.surfaceColors,
                    minimumArea: arState.minRequiredArea, isPreparing: arState.isPreparingBoard,
                    onNext: viewModel.beginPlacement, onConfirm: { Task { await viewModel.confirmBoard() } })
            }
            if viewModel.match?.phase == .promptingForCarry, viewModel.canAct, arState.placementPhase == .confirmed {
                CarryChoiceModalView(onSeparate: { viewModel.resolveCarry(false) }, onCarry: { viewModel.resolveCarry(true) })
                    .zIndex(4)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { viewModel.resume() }
        .onDisappear { viewModel.pause() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { viewModel.pause() }
            else if phase == .active { viewModel.resume() }
        }
        .onChange(of: arState.placementPhase) { viewModel.resumePhase() }
    }
}
