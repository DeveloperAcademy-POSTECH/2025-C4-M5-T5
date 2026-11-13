import SwiftUI

struct PlayView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var viewModel: PlayViewModel
    @ObservedObject private var arState: ARState

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
            if viewModel.match != nil, arState.placementPhase == .confirmed {
                YutGatheringSequenceView(frames: viewModel.scene.gatheringFrames, isPlaying: viewModel.match?.phase == .gathering)
                    .ignoresSafeArea().zIndex(3).padding(.top, 40)
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
                if viewModel.canAct, state.phase == .selectingDestination,
                   state.availableDestinations.contains(where: \.isFinish) {
                    FinishActionView(colors: viewModel.turnPieceType?.surfaceColors,
                        position: viewModel.scene.finishActionPosition, onFinish: viewModel.finishPiece)
                        .ignoresSafeArea()
                }
                PlayControls(state: state, canAct: viewModel.canAct,
                    playerProgress: viewModel.playerProgress,
                    usesManualThrow: arState.usesManualThrow, showsHand: arState.showFinalFrame,
                    onGather: viewModel.beginThrow, onThrow: viewModel.throwManually,
                    onNewPiece: viewModel.placeNewPiece, onCancelSelection: viewModel.cancelSelection)
            } else if viewModel.match != nil {
                PlacementControls(phase: viewModel.placementControlsPhase, area: arState.recognizedArea,
                    isHost: viewModel.isHost,
                    colors: viewModel.scanningPieceType?.surfaceColors,
                    minimumArea: arState.minRequiredArea, isPreparing: arState.isPreparingBoard,
                    onNext: viewModel.beginPlacement, onConfirm: { Task { await viewModel.confirmBoard() } })
            }
            if let state = viewModel.match, state.phase == .choosingMoveResult,
               viewModel.canAct, arState.placementPhase == .confirmed {
                MoveResultChoiceView(choices: state.destinationResultChoices,
                    colors: viewModel.turnPieceType?.surfaceColors,
                    onChoose: viewModel.chooseMoveResult, onCancel: viewModel.cancelSelection)
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
