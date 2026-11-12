import ARKit
import RealityKit

/// 정확한 3D 선택과 탭 시 44pt 보정을 함께 사용한다. 말 재선택은 목적지 선택보다 우선한다.
@MainActor
final class GestureHandler {
    weak var coordinator: ARCoordinator?
    weak var arView: ARView?
    var initialBoardScale: SIMD3<Float>?
    var panOffset: SIMD3<Float>?
    var initialBoardRotation: simd_quatf?

    init(coordinator: ARCoordinator) { self.coordinator = coordinator }

    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let arView, let coordinator else { return }
        let point = recognizer.location(in: arView)
        if coordinator.arState.placementPhase == .placing { coordinator.placeBoard(at: point) }
        else { handleGameTap(at: point, hitEntity: arView.entity(at: point)) }
    }

    func handleGameTap(at point: CGPoint, hitEntity: Entity?) {
        guard let view = arView, let scene = coordinator, scene.canAct,
              scene.arState.placementPhase == .confirmed, let state = scene.latestState,
              [.selectingPiece, .selectingDestination].contains(state.phase),
              point.x.isFinite, point.y.isFinite, view.bounds.contains(point) else { return }
        let manager = scene.arState.gameManager
        if let piece = BoardTapResolver.piece(from: hitEntity, among: manager.pieces) {
            if piece.owner.id == state.currentPlayer?.id { scene.selectPiece(piece.id); return }
            if state.phase == .selectingPiece { return }
        }
        if state.phase == .selectingDestination,
           let exact = BoardTapResolver.destination(from: hitEntity, allowed: state.availableDestinations.map({ $0.isHome ? "_6_6" : $0.cell })) {
            scene.selectDestination(exact)
            return
        }
        var targets = state.currentPieces.compactMap { value -> BoardTapTarget? in
            guard value.cell != nil, let result = state.latestResult, !GameBoard.destinations(for: value, result: result).isEmpty,
                  let piece = manager.pieces.first(where: { $0.id == value.id }) else { return nil }
            return screenTarget(action: .piece(piece.id), entity: piece.entity,
                                center: piece.entity.visualBounds(relativeTo: piece.entity).center, in: view)
        }
        if state.phase == .selectingDestination, let board = scene.boardManager?.yutBoardAnchor {
            targets += state.availableDestinations.compactMap { destination -> BoardTapTarget? in
                let name = destination.isHome ? "_6_6" : destination.cell
                guard let tile = board.findEntity(named: name) else { return nil }
                let center = (tile as? ModelEntity)?.model?.mesh.bounds.center ?? .zero
                return screenTarget(action: .destination(name), entity: tile, center: center, in: view)
            }
        }
        switch BoardTapResolver.closestTarget(to: point, among: targets) {
        case .piece(let id): scene.selectPiece(id)
        case .destination(let name): scene.selectDestination(name)
        case nil: break
        }
    }

    private func screenTarget(action: BoardTapTarget.Action, entity: Entity, center: SIMD3<Float>, in view: ARView) -> BoardTapTarget? {
        guard entity.isActive else { return nil }
        return BoardTapResolver.projectedTarget(action: action, worldPosition: entity.convert(position: center, to: nil),
            cameraTransform: view.cameraTransform.matrix, viewport: view.bounds, project: { view.project($0) })
    }

    // 크기 조절 제스처: 줌인 줌아웃 할 때 호출
    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        
        // 변경: Coordinator 를 통해 필요한 정보 접근
        guard let arState = coordinator?.arState,
              let boardAnchor = coordinator?.boardManager?.yutBoardAnchor else {
            return
        }
        
        // 윷판을 조정하는 상태인지 확인
        guard coordinator?.isHost == true, arState.gamePhase == .adjustingBoard, !arState.isPreparingBoard else { return }
        
        switch recognizer.state {
        case .began:    // 제스쳐 시작: 현재 크기 저장
            initialBoardScale = boardAnchor.scale
        case .changed:  // 제스쳐 중: 초기 크기 * 제스쳐 스케일
            if let initialScae = initialBoardScale {
                boardAnchor.scale = initialScae * Float(recognizer.scale)
            }
        default:        // 제스쳐 종료: 초기화
            initialBoardScale = nil
        }
    }
    
    // 위치 조절 제스쳐: 드래그 할 때 호출
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        
        // 변경: Coordinator 를 통해 필요한 정보 접근
        guard let arView = self.arView,
              let arState = coordinator?.arState,
              let boardAnchor = coordinator?.boardManager?.yutBoardAnchor else {
            return
        }
        
        guard coordinator?.isHost == true, arState.gamePhase == .adjustingBoard, !arState.isPreparingBoard else { return }
        
        // 수평면 위의 3D 좌표 얻기
        let panLocaton = recognizer.location(in: arView)
        guard let result = arView.raycast(from: panLocaton, allowing: .existingPlaneGeometry, alignment: .horizontal).first else {
            return
        }
        let hitPosition = Transform(matrix: result.worldTransform).translation
        
        switch recognizer.state {
        case .began:        // 제스쳐 시작: (윷판의 현재 위치 - 터치된 지점) 차이 계산
            panOffset = boardAnchor.position - hitPosition
        case .changed:      // 제스쳐 중: 터치된 지점 + 저장해둔 오프셋 = 윷판 새 위치 계산
            if let offset = panOffset {
                boardAnchor.position = hitPosition + offset
            }
        default:            // 제스쳐 종료: 오프셋 초기화
            panOffset = nil
        }
    }
    
    @objc func handleRotation(_ recognizer: UIRotationGestureRecognizer) {
        // 변경: Coordinator 를 통해 필요한 정보 접근
        guard let arState = coordinator?.arState,
              let boardAnchor = coordinator?.boardManager?.yutBoardAnchor else {
            return
        }
        
        guard coordinator?.isHost == true, arState.gamePhase == .adjustingBoard, !arState.isPreparingBoard else { return }
        
        switch recognizer.state {
        case .began:        // 제스쳐 시작: 현재 회전 값을 저장
            initialBoardRotation = boardAnchor.orientation
        case .changed:      // 제스쳐 중: 제스쳐의 회전 값 -> 회전 쿼터니언 생성
            // Y축 기준 회전
            let rotation = simd_quatf(
                angle: -Float(recognizer.rotation),
                axis: [0, 1, 0]
            )
            if let initialRotation = initialBoardRotation {
                boardAnchor.orientation = initialRotation * rotation
            }
        default:            // 제스쳐 종료: 초기화
            initialBoardRotation = nil
        }
    }
    
}
