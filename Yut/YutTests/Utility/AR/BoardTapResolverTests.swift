import Foundation
import RealityKit
import simd
import Testing
@testable import Yut

@MainActor
struct BoardTapResolverTests {
    @Test
    func expandedAreaAcceptsEdgesAndRejectsPointsOutside44Points() {
        let target = BoardTapTarget(action: .destination("A"), center: CGPoint(x: 100, y: 100), depth: 1)
        for point in [CGPoint(x: 78, y: 78), CGPoint(x: 122, y: 122), CGPoint(x: 100, y: 80)] {
            #expect(BoardTapResolver.closestTarget(to: point, among: [target]) == .destination("A"))
        }
        #expect(BoardTapResolver.closestTarget(to: CGPoint(x: 122.1, y: 100), among: [target]) == nil)
        #expect(BoardTapResolver.closestTarget(to: CGPoint(x: 100, y: 122.1), among: [target]) == nil)
    }

    @Test
    func overlappingTargetsChooseClosestCenterRegardlessOfArrayOrder() {
        let a = BoardTapTarget(action: .destination("A"), center: CGPoint(x: 100, y: 100), depth: 1)
        let b = BoardTapTarget(action: .destination("B"), center: CGPoint(x: 120, y: 100), depth: 2)
        let point = CGPoint(x: 116, y: 100)
        #expect(BoardTapResolver.closestTarget(to: point, among: [a, b]) == .destination("B"))
        #expect(BoardTapResolver.closestTarget(to: point, among: [b, a]) == .destination("B"))
    }

    @Test
    func coincidentTargetsUseDepthThenStableIdentity() {
        let a = BoardTapTarget(action: .destination("A"), center: .zero, depth: 2)
        let b = BoardTapTarget(action: .destination("B"), center: .zero, depth: 1)
        let c = BoardTapTarget(action: .destination("C"), center: .zero, depth: 1)
        #expect(BoardTapResolver.closestTarget(to: .zero, among: [a, b]) == .destination("B"))
        #expect(BoardTapResolver.closestTarget(to: .zero, among: [c, b]) == .destination("B"))
        #expect(BoardTapResolver.closestTarget(to: .zero, among: [b, c]) == .destination("B"))
    }

    @Test
    func invalidCentersDepthAndTouchCoordinatesNeverSelect() {
        let targets = [
            BoardTapTarget(action: .destination("NaN"), center: CGPoint(x: CGFloat.nan, y: 0), depth: 1),
            BoardTapTarget(action: .destination("Behind"), center: .zero, depth: -1),
            BoardTapTarget(action: .destination("Camera"), center: .zero, depth: 0),
            BoardTapTarget(action: .destination("Infinity"), center: .zero, depth: .infinity)
        ]
        #expect(BoardTapResolver.closestTarget(to: .zero, among: targets) == nil)
        #expect(BoardTapResolver.closestTarget(to: CGPoint(x: CGFloat.nan, y: 0), among: targets) == nil)
    }

    @Test
    func projectionExcludesBehindCameraOffscreenAndInvalidPoints() {
        let viewport = CGRect(x: 0, y: 0, width: 400, height: 800)
        var projectionCount = 0
        let behind = BoardTapResolver.projectedTarget(action: .destination("A"), worldPosition: [0, 0, 1],
            cameraTransform: matrix_identity_float4x4, viewport: viewport) { _ in
                projectionCount += 1
                return CGPoint(x: 100, y: 100)
            }
        #expect(behind == nil)
        #expect(projectionCount == 0)
        for point: CGPoint? in [nil, CGPoint(x: -1, y: 100), CGPoint(x: CGFloat.nan, y: 100)] {
            let target = BoardTapResolver.projectedTarget(action: .destination("A"), worldPosition: [0, 0, -1],
                cameraTransform: matrix_identity_float4x4, viewport: viewport, project: { _ in point })
            #expect(target == nil)
        }
    }

    @Test
    func projectionUsesCurrentCameraPoseAndPreservesAction() throws {
        var camera = matrix_identity_float4x4
        camera.columns.3 = [2, 0, 3, 1]
        let action = BoardTapTarget.Action.piece(UUID())
        let target = try #require(BoardTapResolver.projectedTarget(action: action, worldPosition: [2, 0, 2],
            cameraTransform: camera, viewport: CGRect(x: 0, y: 0, width: 400, height: 800),
            project: { _ in CGPoint(x: 200, y: 400) }))
        #expect(target.action == action)
        #expect(target.center == CGPoint(x: 200, y: 400))
        #expect(target.depth == 1)
    }

    @Test
    func deeplyNestedMeshesResolveToTheirPiece() throws {
        let owner = PlayerModel(name: "Host", sequence: 1, peerID: .init(displayName: "Host"))
        let piece = try #require(owner.pieces.first)
        let group = Entity()
        let nested = Entity()
        let mesh = Entity()
        piece.entity.addChild(group)
        group.addChild(nested)
        nested.addChild(mesh)
        #expect(BoardTapResolver.piece(from: mesh, among: owner.pieces) === piece)
        #expect(BoardTapResolver.piece(from: Entity(), among: owner.pieces) == nil)
    }

    @Test
    func destinationLookupSkipsUnrelatedNamesAndBoardCollider() {
        let tile = Entity()
        tile.name = "_2_6"
        let group = Entity()
        group.name = "_mesh_part"
        let mesh = Entity()
        tile.addChild(group)
        group.addChild(mesh)
        #expect(BoardTapResolver.destination(from: mesh, allowed: ["_2_6"]) == "_2_6")
        #expect(BoardTapResolver.destination(from: mesh, allowed: ["_4_6"]) == nil)
        let collider = Entity()
        collider.name = "YutBoardCollision"
        #expect(BoardTapResolver.destination(from: collider, allowed: ["_2_6"]) == nil)
    }
}
