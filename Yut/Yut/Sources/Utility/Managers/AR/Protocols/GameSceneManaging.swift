import Foundation
import RealityKit

@MainActor
protocol GameSceneManaging: AnyObject {
    var arState: ARState { get }
    var gatheringFrames: GatheringFrameCache { get }
    var onAction: ((GameAction) -> Void)? { get set }
    var onWillThrow: (() -> Bool)? { get set }
    var onResult: ((YutResult) -> Void)? { get set }
    var onSpaceMessage: ((GameMessage) -> Void)? { get set }
    var onSuspended: (() -> Void)? { get set }
    func configure(isHost: Bool, hasRemotePlayers: Bool)
    func setScanningPlayer(order: Int?)
    func makeView() -> ARView
    func resume()
    func pause()
    func reset()
    func retry()
    func beginPlacement()
    func confirmBoard() async
    func shareSavedBoard()
    func render(_ state: GameState, models: [PlayerModel], canAct: Bool, force: Bool)
    func startMotion()
    func throwManually()
    func playGatheringSound()
    func captureLaunch() throws -> YutThrowLaunch
    func receiveBoard(_ board: SharedBoard) throws
    func receiveCollaboration(_ data: Data) throws
    func showRemoteFrame(_ frame: ThrowFrame)
}
