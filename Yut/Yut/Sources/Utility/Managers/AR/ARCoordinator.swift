import ARKit
import AVFoundation
import Combine
import Foundation
import OSLog
import QuartzCore
import RealityKit

/// AR 준비·공유 공간·원본 투사 자원 수명을 관리한다. 게임 규칙과 권한은 주입된 조정자에게 위임한다.
@MainActor
final class ARCoordinator: NSObject, ARSessionDelegate, GameSceneManaging {
    let arState: ARState
    let assetCacheManager: AssetCacheManager
    let sound: any GameSoundPlaying
    var gatheringFrames: GatheringFrameCache { assetCacheManager.gatheringFrames }
    private(set) var arView: ARView?
    private(set) var boardManager: BoardManager?
    let planeManager = PlaneManager()
    private(set) var pieceManager: PieceManager?
    lazy var gestureHandler = GestureHandler(coordinator: self)
    lazy var yutManager = YutManager(coordinator: self, sound: sound)
    var onAction: ((GameAction) -> Void)?
    var onWillThrow: (() -> Bool)?
    var onResult: ((YutResult) -> Void)?
    var onSpaceMessage: ((GameMessage) -> Void)?
    var onSuspended: (() -> Void)?
    private(set) var latestState: GameState?
    private(set) var canAct = false
    private(set) var isHost = false
    private var hasRemotePlayers = false
    private var isRunning = false
    private var assetsReady = false
    private var boardConfirmed = false
    private var loadTask: Task<Void, Never>?
    private var frameTask: Task<Void, Never>?
    private var frameSequence = 0
    private var throwStartedAt: TimeInterval?
    private var localCollisionTimestamp: TimeInterval?
    private var didPlayRemoteCollision = false
    private var remotePlayback = RemoteThrowPlayback()
    private var remoteDisplayLink: CADisplayLink?
    private var areaObservation: AnyCancellable?
    private var thermalTask: Task<Void, Never>?
    private var baseRenderOptions: ARView.RenderOptions?
    private let signposter = OSSignposter(subsystem: "YUT", category: "ARPerformance")
    private var generation = UUID()
    private var pendingBoard: SharedBoard?
    private var savedBoard: SharedBoard?
    private var sharedAnchorID: UUID?
    private var remoteAnchor: AnchorEntity?
    private var remoteModels: [Int: ModelEntity] = [:]
    private var activeThrowRevision: Int?
    private var pendingFrame: ThrowFrame?
    private var finalRemoteFrame: ThrowFrame?
    private var previousState: GameState?
    private var playerModels: [PlayerModel] = []

    init(state: ARState, assets: AssetCacheManager, sound: any GameSoundPlaying) {
        arState = state
        assetCacheManager = assets
        self.sound = sound
        super.init()
        state.coordinator = self
    }

    func configure(isHost: Bool, hasRemotePlayers: Bool) {
        self.isHost = isHost
        let changed = self.hasRemotePlayers != hasRemotePlayers
        self.hasRemotePlayers = hasRemotePlayers
        if changed, isRunning, let view = arView, let configuration = view.session.configuration as? ARWorldTrackingConfiguration {
            configuration.isCollaborationEnabled = hasRemotePlayers
            view.session.run(configuration)
        }
    }

    func setScanningPlayer(order: Int?) {
        let color = order.flatMap { PieceType.from(sequence: $0 + 1) }?.surfaceColors.background ?? ThemeColors.canvas
        planeManager.setVisualizationColor(UIColor(color))
    }

    func makeView() -> ARView {
        if let arView { resume(); return arView }
#if targetEnvironment(simulator)
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(UIColor(named: "white1") ?? .white)
        // 시뮬레이터의 지원하지 않는 그림자 렌더 타깃을 제외한다. 실기기 렌더 옵션은 유지한다.
        view.renderOptions.insert(.disableGroundingShadows)
#else
        let view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
#endif
        arView = view
        baseRenderOptions = view.renderOptions
        boardManager = BoardManager(scene: view.scene, assets: assetCacheManager)
        planeManager.scene = view.scene
        gestureHandler.arView = view
        let gestures = [
            UITapGestureRecognizer(target: gestureHandler, action: #selector(GestureHandler.handleTap)),
            UIPinchGestureRecognizer(target: gestureHandler, action: #selector(GestureHandler.handlePinch)),
            UIPanGestureRecognizer(target: gestureHandler, action: #selector(GestureHandler.handlePan)),
            UIRotationGestureRecognizer(target: gestureHandler, action: #selector(GestureHandler.handleRotation))
        ]
        gestures.forEach { view.addGestureRecognizer($0) }
        areaObservation = planeManager.recognizedAreaPublisher.sink { [weak self] area in
            guard let self else { return }
            if arState.recognizedArea != area { arState.recognizedArea = area }
            if isHost, area >= arState.minRequiredArea, arState.placementPhase == .scanning { setPlacement(.placing) }
        }
        resume()
        return view
    }

    /// 평면 감지는 LiDAR 메시의 평탄화에도 쓰이므로 배치 후에도 실제 사물 충돌을 위해 유지한다.
    private func configuration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) { configuration.sceneReconstruction = .mesh }
        configuration.isCollaborationEnabled = hasRemotePlayers
        return configuration
    }

    func resume() {
        guard let view = arView, !isRunning, loadTask == nil else { return }
        let expected = generation
        loadTask = Task { [weak self] in
            guard let self else { return }
            defer { if generation == expected { loadTask = nil } }
            do {
                try await assetCacheManager.preloadAll()
                try Task.checkCancellation()
                guard generation == expected else { return }
                assetsReady = true
#if targetEnvironment(simulator)
                installSimulatorEnvironment(in: view)
#else
                guard ARWorldTrackingConfiguration.isSupported else { throw SceneError.unsupported }
                let granted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized ? true : await AVCaptureDevice.requestAccess(for: .video)
                guard granted else { throw SceneError.cameraDenied }
                try Task.checkCancellation()
#endif
                guard generation == expected else { return }
                sound.prepare()
                isRunning = true
                planeManager.resume()
                observeThermalState()
                view.session.delegateQueue = .main
                view.session.delegate = self
#if !targetEnvironment(simulator)
                view.environment.sceneUnderstanding.options.insert(.physics)
                view.session.run(configuration())
#endif
                if let pendingBoard { try receiveBoard(pendingBoard) }
                else if boardConfirmed {
#if targetEnvironment(simulator)
                    setPlacement(.confirmed)
#else
                    setPlacement(.relocalizing)
#endif
                } else if boardManager?.yutBoardAnchor != nil { setPlacement(.adjusting) }
                else { setPlacement(isHost ? .scanning : .waitingForHost) }
                if let latestState { render(latestState, models: playerModels, canAct: canAct, force: true) }
            } catch is CancellationError { return }
            catch {
                guard generation == expected else { return }
                arState.errorMessage = error.localizedDescription
            }
        }
    }

    func pause() {
        guard isRunning || loadTask != nil else { return }
        isRunning = false
        generation = UUID()
        loadTask?.cancel()
        loadTask = nil
        frameTask?.cancel()
        frameTask = nil
        throwStartedAt = nil
        localCollisionTimestamp = nil
        if pendingFrame?.collisionTimestamp != nil { didPlayRemoteCollision = true }
        stopRemotePlayback()
        thermalTask?.cancel()
        thermalTask = nil
        planeManager.pause()
        yutManager.stop()
        activeThrowRevision = nil
        pieceManager?.stop()
        sound.stop()
        arView?.session.pause()
        arView?.session.delegate = nil
        if boardConfirmed { setPlacement(.relocalizing) }
        onSuspended?()
    }

    func retry() {
        arState.errorMessage = nil
        pause()
        resume()
    }

    func reset() {
        pause()
        generation = UUID()
        pieceManager?.stop()
        pieceManager = nil
        boardManager?.reset()
        planeManager.reset()
        clearRemoteThrow()
        arState.gameManager.reset()
        latestState = nil
        previousState = nil
        savedBoard = nil
        pendingBoard = nil
        sharedAnchorID = nil
        boardConfirmed = false
        activeThrowRevision = nil
        pendingFrame = nil
        finalRemoteFrame = nil
        arState.isCoordinatorReady = false
        arState.showFinalFrame = false
        arState.errorMessage = nil
        assetCacheManager.clearCache()
        assetsReady = false
        setPlacement(.loading)
    }

    func beginPlacement() {
        guard isHost, isRunning else { return }
        setPlacement(.placing)
    }

    func placeBoard(at point: CGPoint) {
        guard isHost, arState.placementPhase == .placing, let view = arView, boardManager?.yutBoardAnchor == nil else { return }
#if targetEnvironment(simulator)
        addBoard(ARAnchor(name: "YutBoardAnchor", transform: matrix_identity_float4x4))
#else
        guard let hit = view.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .horizontal).first else { return }
        view.session.add(anchor: ARAnchor(name: "YutBoardAnchor", transform: hit.worldTransform))
#endif
    }

    func confirmBoard() async {
        guard isHost, !arState.isPreparingBoard, let view = arView, let boardManager, boardManager.yutBoardAnchor != nil else { return }
        let expected = generation
        arState.isPreparingBoard = true
        defer { if generation == expected { arState.isPreparingBoard = false } }
        boardManager.fixBoardPosition()
        if let fixed = boardManager.yutBoardAnchor { pieceManager?.boardAnchor = fixed }
        do {
            if hasRemotePlayers {
                let anchor = ARAnchor(name: "YutSharedBoard", transform: try rigidReference())
                sharedAnchorID = anchor.identifier
                view.session.add(anchor: anchor)
                let map: ARWorldMap = try await withCheckedThrowingContinuation { continuation in
                    view.session.getCurrentWorldMap { map, error in
                        if let error { continuation.resume(throwing: error) }
                        else if let map { continuation.resume(returning: map) }
                        else { continuation.resume(throwing: SceneError.worldMap) }
                    }
                }
                try Task.checkCancellation()
                guard generation == expected, isRunning else { return }
                if !map.anchors.contains(where: { $0.identifier == anchor.identifier }) { map.anchors.append(anchor) }
                let scale = boardManager.yutBoardAnchor.map { Transform(matrix: $0.transformMatrix(relativeTo: nil)).scale.x } ?? 1
                savedBoard = SharedBoard(anchorID: anchor.identifier,
                    worldMap: try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true), scale: scale)
                shareSavedBoard()
            }
            try Task.checkCancellation()
            guard generation == expected, isRunning else { return }
            boardConfirmed = true
            planeManager.disablePlaneVisualization()
            setPlacement(.confirmed)
        } catch is CancellationError { return }
        catch {
            guard generation == expected, isRunning else { return }
            arState.errorMessage = error.localizedDescription
        }
    }

    func shareSavedBoard() {
        guard let board = savedBoard, let id = latestState?.id else { return }
        onSpaceMessage?(.board(gameID: id, board))
    }

    func receiveBoard(_ board: SharedBoard) throws {
        guard board.scale.isFinite, board.scale > 0 else { throw SceneError.worldMap }
        guard isRunning, assetsReady, let view = arView else { pendingBoard = board; return }
        guard let map = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: board.worldMap),
              map.anchors.contains(where: { $0.identifier == board.anchorID }) else { throw SceneError.worldMap }
        if sharedAnchorID == board.anchorID, boardManager?.yutBoardAnchor != nil { return }
        yutManager.stop()
        pieceManager?.stop()
        pieceManager = nil
        boardManager?.reset()
        planeManager.reset()
        planeManager.resume()
        pendingBoard = nil
        savedBoard = board
        sharedAnchorID = board.anchorID
        boardConfirmed = true
        setPlacement(.relocalizing)
        let config = configuration()
        config.initialWorldMap = map
        view.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func receiveCollaboration(_ data: Data) throws {
        guard isRunning, let view = arView, hasRemotePlayers,
              let collaboration = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data) else { return }
        view.session.update(with: collaboration)
    }

    func render(_ state: GameState, models: [PlayerModel], canAct: Bool, force: Bool = false) {
        let previousCanAct = self.canAct
        let sameModels = playerModels.count == models.count && zip(playerModels, models).allSatisfy { $0 === $1 }
        latestState = state
        playerModels = models
        self.canAct = canAct
        guard isRunning, assetsReady, boardManager?.yutBoardAnchor != nil else { return }
        guard force || previousState != state || previousCanAct != canAct || !sameModels else { return }
        do {
            try arState.gameManager.apply(state, assets: assetCacheManager, models: models)
            pieceManager?.render(previous: previousState, current: state, force: force)
            let changedSelection = previousState?.phase != state.phase || previousState?.selectedPieceID != state.selectedPieceID
                || previousState?.availableDestinations != state.availableDestinations || previousCanAct != canAct || force
            if changedSelection {
                if canAct, state.phase == .selectingDestination {
                    pieceManager?.highlightTiles(named: state.availableDestinations.filter { !$0.isFinish }.map { $0.cell })
                } else { pieceManager?.clearAllHighlights() }
            }
            if ![.throwing, .showingResult, .waitingForShake].contains(state.phase),
               force || previousState == nil || previousState?.id != state.id
                || [.throwing, .showingResult, .waitingForShake].contains(previousState?.phase) {
                yutManager.stop()
            }
            let displayedRevision = expectedThrowRevision(state)
            let staleRemoteFrame = pendingFrame.map { $0.gameID != state.id || $0.throwRevision != displayedRevision } ?? false
            if canAct || displayedRevision == nil || staleRemoteFrame {
                clearRemoteThrow()
            } else if let pendingFrame { showRemoteFrame(pendingFrame) }
            if arState.yutResult != state.latestResult { arState.yutResult = state.latestResult }
            let showsHand = state.phase == .waitingForShake
            if arState.showFinalFrame != showsHand { arState.showFinalFrame = showsHand }
            previousState = state
            updateLegacyPhase()
        } catch { arState.errorMessage = error.localizedDescription }
    }

    func startMotion() {
        guard canAct, isRunning, arState.placementPhase == .confirmed, latestState?.phase == .waitingForShake else { return }
        if !yutManager.isMotionAvailable { motionFailed() }
        else if !arState.usesManualThrow { yutManager.startMonitoringMotion() }
    }

    func throwManually() { yutManager.throwManually() }
    func playGatheringSound() { sound.playCollectYutSound() }

    func motionFailed() { arState.usesManualThrow = true }

    /// 참가자도 송신 성공 즉시 원본 투사를 시작한다. 승인 스냅샷을 기다리며 흔들기 반응을 늦추지 않는다.
    func beginLocalThrow() -> Bool {
        guard isRunning, canAct, arState.placementPhase == .confirmed, latestState?.phase == .waitingForShake,
              activeThrowRevision == nil, onWillThrow?() == true else { return false }
        activeThrowRevision = latestState?.phase == .throwing ? latestState?.revision : (latestState?.revision).map { $0 + 1 }
        frameSequence = 0
        throwStartedAt = CACurrentMediaTime()
        localCollisionTimestamp = nil
        startFrameBroadcast()
        return true
    }

    /// 원본 충돌음의 재생 시각을 다음 자세 프레임부터 함께 전달한다.
    func didPlayLocalCollisionSound() {
        guard isRunning, canAct, activeThrowRevision != nil, localCollisionTimestamp == nil,
              let throwStartedAt else { return }
        localCollisionTimestamp = max(0, CACurrentMediaTime() - throwStartedAt)
    }

    func yutThrowCompleted(with result: YutResult) {
        guard canAct, isRunning, activeThrowRevision != nil else { return }
        broadcastFrame(final: true)
        frameTask?.cancel()
        frameTask = nil
        onResult?(result)
    }

    func selectPiece(_ id: UUID) {
        guard canAct, isRunning, arState.placementPhase == .confirmed,
              let state = latestState, [.selectingPiece, .selectingDestination].contains(state.phase),
              let piece = state.pieces.first(where: { $0.id == id }), piece.playerID == state.currentPlayer?.id,
              state.canMove(piece) else { return }
        if state.phase == .selectingDestination {
            // 선택 중인 말은 유지한다. 다른 내 말 탭은 유효한 목적지일 때만 자동 업기로 연결한다.
            guard let selected = state.selectedPiece, selected.groupID != piece.groupID,
                  let destination = state.availableDestinations.first(where: { $0.cell == piece.cell }) else { return }
            onAction?(.selectDestination(destination))
        } else {
            onAction?(.selectPiece(id))
        }
    }

    /// ARView 전체 좌표계의 출발점. 화면 밖이거나 카메라 뒤에 있으면 표시하지 않는다.
    func finishActionPosition() -> CGPoint? {
        guard isRunning, canAct, arState.placementPhase == .confirmed,
              latestState?.phase == .selectingDestination,
              latestState?.availableDestinations.contains(where: \.isFinish) == true,
              let view = arView, let position = pieceManager?.worldPosition(ofTile: "_6_6") else { return nil }
        return BoardTapResolver.projectedTarget(action: .destination("end"),
            worldPosition: position, cameraTransform: view.cameraTransform.matrix,
            viewport: view.bounds, project: { view.project($0) })?.center
    }

    func selectDestination(_ name: String) {
        guard canAct, isRunning, let destination = latestState?.availableDestinations.first(where: { !$0.isFinish && ($0.cell) == name }) else { return }
        onAction?(.selectDestination(destination))
    }

    func captureLaunch() throws -> YutThrowLaunch {
        guard let view = arView else { throw SceneError.cameraDenied }
#if targetEnvironment(simulator)
        let camera = view.cameraTransform.matrix
#else
        guard let camera = view.session.currentFrame?.camera.transform else { throw SceneError.tracking }
#endif
        let relative = simd_inverse(try rigidReference()) * camera
        return YutThrowLaunch(cameraPosition: SIMD3(relative.columns.3.x, relative.columns.3.y, relative.columns.3.z),
            cameraRotation: simd_quatf(relative).vector,
            yutLocalRotation: (simd_quatf(angle: .pi / 2, axis: [0, 0, 1]) * simd_quatf(camera)).vector)
    }

    private func rigidReference() throws -> simd_float4x4 {
        guard let anchor = boardManager?.yutBoardAnchor else { throw SceneError.tracking }
        var transform = Transform(matrix: anchor.transformMatrix(relativeTo: nil))
        transform.scale = SIMD3(repeating: 1)
        return transform.matrix
    }

    private func startFrameBroadcast() {
        guard hasRemotePlayers else { return }
        frameTask?.cancel()
        frameTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(50)) } catch { return }
                self?.broadcastFrame(final: false)
            }
        }
    }

    private func broadcastFrame(final: Bool) {
        guard hasRemotePlayers, let revision = activeThrowRevision, let id = latestState?.id,
              yutManager.thrownYuts.count == 4, yutManager.thrownYuts.allSatisfy({ $0.entity.scene != nil }), let reference = try? rigidReference() else { return }
        let poses = yutManager.thrownYuts.enumerated().map { index, value -> ThrowFrame.Pose in
            let transform = Transform(matrix: simd_inverse(reference) * value.entity.transformMatrix(relativeTo: nil))
            return .init(index: index, position: transform.translation, rotation: transform.rotation.vector, scale: transform.scale)
        }
        frameSequence += 1
        let timestamp = throwStartedAt.map { max(0, CACurrentMediaTime() - $0) }
        let frame = ThrowFrame(gameID: id, throwRevision: revision, poses: poses, isFinal: final,
                               sequence: frameSequence, timestamp: timestamp, collisionTimestamp: localCollisionTimestamp)
        if frame.isValid { onSpaceMessage?(.throwFrame(frame)) }
    }

    func showRemoteFrame(_ frame: ThrowFrame) {
        guard frame.isValid, !canAct, let state = latestState, frame.gameID == state.id else { return }
        guard frame.throwRevision == expectedThrowRevision(state) else { return }
        if let finalRemoteFrame, finalRemoteFrame.gameID == frame.gameID,
           finalRemoteFrame.throwRevision == frame.throwRevision, frame != finalRemoteFrame { return }
        if let pendingFrame, pendingFrame.gameID == frame.gameID,
           pendingFrame.throwRevision == frame.throwRevision {
            if frame.sequence < pendingFrame.sequence { return }
            if frame.sequence == pendingFrame.sequence, frame != pendingFrame { return }
            if let currentTime = frame.timestamp, let previousTime = pendingFrame.timestamp, currentTime < previousTime { return }
        }
        pendingFrame = frame
        if frame.isFinal { finalRemoteFrame = frame }
        guard isRunning, arState.placementPhase == .confirmed, let view = arView else {
            if frame.collisionTimestamp != nil { didPlayRemoteCollision = true }
            return
        }
        let now = CACurrentMediaTime()
        remotePlayback.append(frame, receivedAt: now)
        if remoteAnchor == nil {
            let anchor = AnchorEntity(world: .zero)
            view.scene.addAnchor(anchor)
            remoteAnchor = anchor
        }
        for pose in frame.poses {
            let entity: ModelEntity
            if let cached = remoteModels[pose.index] { entity = cached }
            else {
                let names = ["Yut1", "Yut2", "Yut3", "Yut4_back"]
                guard let template = assetCacheManager.cachedModel(named: names[pose.index]) else { continue }
                entity = template.clone(recursive: true)
                stripPhysics(entity)
                remoteAnchor?.addChild(entity)
                remoteModels[pose.index] = entity
            }
        }
        presentRemoteFrame(at: now)
        if !remotePlayback.reachedFinal, remoteDisplayLink == nil {
            let link = CADisplayLink(target: self, selector: #selector(updateRemotePlayback))
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
            link.add(to: .main, forMode: .common)
            remoteDisplayLink = link
        }
    }

    private func expectedThrowRevision(_ state: GameState) -> Int? {
        switch state.phase {
        case .throwing: state.revision
        case .showingResult: state.revision - 1
        default: nil
        }
    }

    @objc private func updateRemotePlayback() {
        let now = CACurrentMediaTime()
        guard isRunning, arState.placementPhase == .confirmed else { stopRemotePlayback(); return }
        // 통신이 멈춘 동안 마지막 자세를 유지하고 프레임 작업을 계속 돌리지 않는다.
        if let received = remotePlayback.lastReceivedAt, now - received > 1 { invalidateRemoteLink(); return }
        presentRemoteFrame(at: now)
    }

    private func presentRemoteFrame(at time: TimeInterval) {
        guard let reference = try? rigidReference(), let poses = remotePlayback.poses(at: time) else { return }
        for pose in poses {
            remoteModels[pose.index]?.setTransformMatrix(reference * Transform(
                scale: pose.scale, rotation: simd_quatf(vector: pose.rotation), translation: pose.position
            ).matrix, relativeTo: nil)
        }
        if remotePlayback.consumeCollision(at: time), !didPlayRemoteCollision {
            sound.playCollisionSound()
            didPlayRemoteCollision = true
        }
        if remotePlayback.reachedFinal { invalidateRemoteLink() }
    }

    private func invalidateRemoteLink() {
        remoteDisplayLink?.invalidate()
        remoteDisplayLink = nil
    }

    private func stopRemotePlayback() {
        invalidateRemoteLink()
        remotePlayback.reset()
    }

    private func clearRemoteThrow() {
        stopRemotePlayback()
        didPlayRemoteCollision = false
        remoteAnchor?.removeFromParent()
        remoteAnchor = nil
        remoteModels = [:]
        pendingFrame = nil
        finalRemoteFrame = nil
    }

    private func stripPhysics(_ entity: Entity) {
        entity.components.remove(PhysicsBodyComponent.self)
        entity.components.remove(PhysicsMotionComponent.self)
        entity.components.remove(CollisionComponent.self)
        entity.children.forEach { stripPhysics($0) }
    }

    private func addBoard(_ anchor: ARAnchor) {
        guard boardManager?.yutBoardAnchor == nil else { return }
        boardManager?.placeYutBoard(on: anchor)
        guard let boardAnchor = boardManager?.yutBoardAnchor else { return }
        if !isHost, let savedBoard { boardAnchor.scale = SIMD3(repeating: savedBoard.scale) }
        pieceManager = PieceManager(boardAnchor: boardAnchor, gameManager: arState.gameManager)
        arState.isCoordinatorReady = true
        if boardConfirmed {
            planeManager.disablePlaneVisualization()
#if targetEnvironment(simulator)
            setPlacement(.confirmed)
#endif
        } else { setPlacement(.adjusting) }
        if let latestState { render(latestState, models: playerModels, canAct: canAct, force: true) }
    }

    private func setPlacement(_ phase: BoardPlacementPhase) {
        if arState.placementPhase != phase {
            signposter.emitEvent("PlacementPhase", "\(String(describing: phase))")
            arState.placementPhase = phase
        }
        updateLegacyPhase()
    }

    private func observeThermalState() {
        updateThermalRendering()
        thermalTask?.cancel()
        thermalTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: ProcessInfo.thermalStateDidChangeNotification) {
                guard !Task.isCancelled, let self, isRunning else { return }
                updateThermalRendering()
            }
        }
    }

    /// 발열이 심할 때 후처리만 줄인다. 물리 시간 간격·카메라 추적·그림자·공간 충돌은 유지한다.
    private func updateThermalRendering() {
        guard let arView, let baseRenderOptions else { return }
        switch ProcessInfo.processInfo.thermalState {
        case .serious, .critical:
            arView.renderOptions = baseRenderOptions.union([.disableMotionBlur, .disableDepthOfField, .disableCameraGrain])
        default:
            arView.renderOptions = baseRenderOptions
        }
        signposter.emitEvent("ThermalState", "\(ProcessInfo.processInfo.thermalState.rawValue)")
    }

    private func updateLegacyPhase() {
        let phase: GamePhase
        if arState.placementPhase != .confirmed {
            switch arState.placementPhase {
            case .loading: phase = .arSessionLoading
            case .scanning, .waitingForHost, .relocalizing: phase = .scanningPlanes
            case .placing: phase = .placingBoard
            case .adjusting: phase = .adjustingBoard
            case .confirmed: phase = .boardConfirmed
            }
        } else {
            switch latestState?.phase {
            case .preparing, nil: phase = .boardConfirmed
            case .readyToThrow, .gathering, .waitingForShake, .throwing: phase = .readyToThrow
            case .showingResult, .showingBonus: phase = .showingYutResult
            case .selectingPiece: phase = .selectingPieceToMove
            case .selectingDestination, .choosingMoveResult: phase = .selectingDestination
            case .movingPiece: phase = .selectingPieceToMove
            case .finished: phase = .boardConfirmed
            }
        }
        if arState.gamePhase != phase { arState.gamePhase = phase }
        if latestState?.phase != .throwing && latestState?.phase != .showingResult { activeThrowRevision = nil }
    }

#if targetEnvironment(simulator)
    private func installSimulatorEnvironment(in view: ARView) {
        guard !view.scene.anchors.contains(where: { $0.name == "simulator-environment" }) else { return }
        let anchor = AnchorEntity(world: .zero)
        anchor.name = "simulator-environment"
        anchor.anchoring.physicsSimulation = .none
        let floor = ModelEntity()
        floor.name = "Plane"
        floor.position = [0, -0.005, 0]
        floor.components.set(CollisionComponent(shapes: [.generateBox(size: [10, 0.01, 10])]))
        floor.physicsBody = PhysicsBodyComponent(mode: .static)
        anchor.addChild(floor)
        let camera = PerspectiveCamera()
        camera.look(at: [0, 0.03, 0], from: [0, 1.3, 1.3], relativeTo: nil)
        anchor.addChild(camera)
        let light = DirectionalLight()
        light.light.intensity = 2500
        light.look(at: .zero, from: [0, 1, 1], relativeTo: nil)
        anchor.addChild(light)
        view.scene.addAnchor(anchor)
        arState.recognizedArea = arState.minRequiredArea
    }
#endif

    nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        MainActor.assumeIsolated {
            guard arView?.session === session, isRunning else { return }
            for anchor in anchors {
                if let plane = anchor as? ARPlaneAnchor { planeManager.addPlane(for: plane) }
                else if anchor.name == "YutBoardAnchor" || anchor.identifier == sharedAnchorID { addBoard(anchor) }
            }
        }
    }
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        MainActor.assumeIsolated {
            guard arView?.session === session, isRunning else { return }
            for case let plane as ARPlaneAnchor in anchors { planeManager.updatePlane(for: plane) }
        }
    }
    nonisolated func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        MainActor.assumeIsolated {
            guard arView?.session === session, isRunning else { return }
            for case let plane as ARPlaneAnchor in anchors { planeManager.removePlane(for: plane) }
        }
    }
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        MainActor.assumeIsolated {
            guard arView?.session === session, isRunning, arState.placementPhase == .relocalizing,
                  case .normal = frame.camera.trackingState, boardManager?.yutBoardAnchor?.isAnchored == true else { return }
            setPlacement(.confirmed)
            if let latestState { render(latestState, models: playerModels, canAct: canAct, force: true) }
        }
    }
    nonisolated func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
        MainActor.assumeIsolated {
            guard isRunning, hasRemotePlayers, arView?.session === session, let id = latestState?.id else { return }
            do {
                let encoded = try NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
                onSpaceMessage?(.collaboration(gameID: id, data: encoded, isCritical: data.priority == .critical))
            } catch { arState.errorMessage = error.localizedDescription }
        }
    }
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        MainActor.assumeIsolated {
            guard arView?.session === session, isRunning else { return }
            arState.errorMessage = error.localizedDescription
            pause()
        }
    }
    nonisolated func sessionWasInterrupted(_ session: ARSession) {
        MainActor.assumeIsolated {
            guard arView?.session === session, isRunning else { return }
            yutManager.stop()
            planeManager.pause()
            activeThrowRevision = nil
            frameTask?.cancel()
            throwStartedAt = nil
            stopRemotePlayback()
            arState.placementPhase = .relocalizing
            onSuspended?()
        }
    }
    nonisolated func sessionInterruptionEnded(_ session: ARSession) {
        MainActor.assumeIsolated {
            guard arView?.session === session, session.delegate === self, isRunning else { return }
            planeManager.resume()
            session.run(configuration())
        }
    }

    private enum SceneError: LocalizedError {
        case unsupported, cameraDenied, worldMap, tracking
        var errorDescription: String? {
            switch self {
            case .unsupported: "이 기기는 AR 윷놀이를 지원하지 않습니다."
            case .cameraDenied: "설정에서 카메라 접근을 허용해주세요."
            case .worldMap: "주변 공간을 조금 더 비춘 뒤 말판 공유를 다시 시도해주세요."
            case .tracking: "카메라가 공간을 인식한 뒤 다시 시도해주세요."
            }
        }
    }
}
