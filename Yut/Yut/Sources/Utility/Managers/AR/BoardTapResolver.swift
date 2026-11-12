import Foundation
import RealityKit
import simd

/// 현재 게임 단계에서 선택 가능한 대상의 화면 좌표다. 외형이나 물리 충돌 형상은 변경하지 않는다.
struct BoardTapTarget {
    enum Action: Equatable {
        case piece(UUID)
        case destination(String)

        fileprivate var orderingKey: String {
            switch self {
            case .piece(let id): "0:piece:\(id.uuidString)"
            case .destination(let name): "1:destination:\(name)"
            }
        }
    }

    let action: Action
    let center: CGPoint
    let depth: Float
}

enum BoardTapResolver {
    static let minimumTargetSize: CGFloat = 44

    /// 44×44pt 범위가 겹치면 화면 중심이 가까운 대상을 고른다.
    /// 거리가 같으면 카메라 앞쪽 대상, 깊이까지 같으면 고정 식별자 순으로 선택한다.
    static func closestTarget(to point: CGPoint, among targets: [BoardTapTarget]) -> BoardTapTarget.Action? {
        guard point.x.isFinite, point.y.isFinite else { return nil }
        let radius = minimumTargetSize / 2
        var best: BoardTapTarget?
        var bestDistance = CGFloat.infinity
        for target in targets {
            guard target.center.x.isFinite, target.center.y.isFinite, target.depth.isFinite, target.depth > 0 else { continue }
            let dx = target.center.x - point.x
            let dy = target.center.y - point.y
            guard abs(dx) <= radius, abs(dy) <= radius else { continue }
            let distance = dx * dx + dy * dy
            if let current = best {
                let precedes = target.depth < current.depth || (target.depth == current.depth && target.action.orderingKey < current.action.orderingKey)
                guard distance < bestDistance || (distance == bestDistance && precedes) else { continue }
            }
            best = target
            bestDistance = distance
        }
        return best?.action
    }

    /// 카메라 뒤·화면 밖·유효하지 않은 투영은 터치 보정 후보에서 제외한다.
    static func projectedTarget(action: BoardTapTarget.Action, worldPosition: SIMD3<Float>, cameraTransform: simd_float4x4,
                                viewport: CGRect, project: (SIMD3<Float>) -> CGPoint?) -> BoardTapTarget? {
        guard worldPosition.x.isFinite, worldPosition.y.isFinite, worldPosition.z.isFinite else { return nil }
        let cameraPosition = simd_inverse(cameraTransform) * SIMD4<Float>(worldPosition, 1)
        let depth = -cameraPosition.z
        guard depth.isFinite, depth > 0, let point = project(worldPosition),
              point.x.isFinite, point.y.isFinite, viewport.contains(point) else { return nil }
        return BoardTapTarget(action: action, center: point, depth: depth)
    }

    /// 자식 메시가 여러 단계 중첩돼 있어도 실제 말의 UUID가 있는 조상까지 확인한다.
    @MainActor
    static func piece(from entity: Entity?, among pieces: [PieceModel]) -> PieceModel? {
        var current = entity
        while let candidate = current {
            if let id = UUID(uuidString: candidate.name), let piece = pieces.first(where: { $0.id == id }) { return piece }
            current = candidate.parent
        }
        return nil
    }

    @MainActor
    static func destination(from entity: Entity?, allowed names: [String]) -> String? {
        var current = entity
        while let candidate = current {
            if names.contains(candidate.name) { return candidate.name }
            current = candidate.parent
        }
        return nil
    }
}
