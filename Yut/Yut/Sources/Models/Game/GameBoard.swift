import Foundation

/// 목적지의 칸뿐 아니라 선택한 경로와 이동 구간을 함께 보관하는 이동 후보다.
/// 출발점은 경로 인덱스 0인 판 위 칸이며, `end`는 완주를 나타내는 논리 값이다.
struct MoveDestination: Codable, Equatable, Hashable, Identifiable, Sendable {
    let route: Int
    let index: Int
    let cell: String
    /// 전진할 때 실제로 통과한 위치이며, 이후 빽도에 사용할 이력에 추가한다.
    var traversedPositions: [PiecePosition] = []

    var id: String { "\(route):\(index)" }
    var isFinish: Bool { cell == "end" }
}

/// 엔티티 이름과 일치하는 칸 식별자로 경로를 계산한다. AR 좌표나 렌더링 상태에는 의존하지 않는다.
enum GameBoard {
    /// 바깥길, `_0_0`에서 중앙을 지나는 길, `_0_6`에서 중앙을 지나는 길 순서다.
    /// 각 경로의 첫 칸과 마지막 칸은 이름이 같으므로 진행 위치는 인덱스로 구분한다.
    static let routes = [
        ["_6_6", "_5_6", "_4_6", "_2_6", "_1_6", "_0_6", "_0_5", "_0_4", "_0_2", "_0_1", "_0_0", "_1_0", "_2_0", "_4_0", "_5_0", "_6_0", "_6_1", "_6_2", "_6_4", "_6_5", "_6_6"],
        ["_6_6", "_5_6", "_4_6", "_2_6", "_1_6", "_0_6", "_0_5", "_0_4", "_0_2", "_0_1", "_0_0", "_1_1", "_2_2", "_3_3", "_4_4", "_5_5", "_6_6"],
        ["_6_6", "_5_6", "_4_6", "_2_6", "_1_6", "_0_6", "_1_5", "_2_4", "_3_3", "_4_2", "_5_1", "_6_0", "_6_1", "_6_2", "_6_4", "_6_5", "_6_6"]
    ]

    /// 진행 중인 말의 칸 이름을 반환한다. 판 밖·완주 상태와 유효하지 않은 경로는 `nil`이다.
    static func cell(for position: PiecePosition) -> String? {
        guard case .onBoard(let route, let index) = position,
              routes.indices.contains(route), routes[route].indices.contains(index) else { return nil }
        return routes[route][index]
    }

    /// 빽도는 실제 이동 이력을 거슬러 계산하고, 나머지 결과는 현재 경로에서 계산한다.
    /// 중앙에서 경로를 바꾼 말도 원래 들어온 방향으로 되돌아가야 하므로 이력이 필요하다.
    /// - Returns: 이동할 수 없으면 빈 배열, 분기점에서는 선택 가능한 이동 후보들.
    static func destinations(for piece: GamePiece, result: YutResult) -> [MoveDestination] {
        guard result == .backdho else { return destinations(from: piece.position, result: result) }
        guard case .onBoard(let route, let index) = piece.position,
              routes.indices.contains(route), routes[route].indices.contains(index) else { return [] }
        if index == 0 { return [destination(route: route, index: routes[route].count)] }
        let previous = piece.history.dropLast().last ?? .home
        if case .onBoard(let route, let index) = previous {
            return [destination(route: route, index: index)]
        }
        return [destination(route: 0, index: 0)]
    }

    /// 현재 위치를 기준으로 모서리·중앙의 분기와 완주 여부를 계산한다.
    /// 실제 말의 빽도에는 이동 이력을 반영하는 `destinations(for:result:)`를 사용한다.
    /// - Returns: 낙·완주 상태·판 밖의 빽도에는 빈 배열을 반환한다.
    static func destinations(from position: PiecePosition, result: YutResult) -> [MoveDestination] {
        guard result != .nak else { return [] }
        switch position {
        case .finished:
            return []
        case .home:
            guard result.moveCount > 0 else { return [] }
            return [forwardDestination(route: 0, from: 0, steps: result.moveCount)]
        case .onBoard(let route, let index):
            guard routes.indices.contains(route), routes[route].indices.contains(index) else { return [] }
            if result == .backdho {
                return [destination(route: route, index: index == 0 ? routes[route].count : index - 1)]
            }
            let cell = routes[route][index]
            let options: [Int]
            switch cell {
            case "_0_6": options = [0, 2]
            case "_0_0": options = [0, 1]
            case "_3_3": options = [1, 2]
            default: options = [route]
            }
            var destinations: [MoveDestination] = []
            for option in options {
                // 같은 경로에서는 현재 인덱스를 유지해 도착 칸이 출발 칸으로 해석되는 것을 막는다.
                let start = option == route ? index : routes[option].firstIndex(of: cell)
                guard let start else { continue }
                let target = forwardDestination(route: option, from: start, steps: result.moveCount)
                if !destinations.contains(where: { $0.cell == target.cell }) {
                    destinations.append(target)
                }
            }
            return destinations
        }
    }

    private static func forwardDestination(route: Int, from index: Int, steps: Int) -> MoveDestination {
        var target = destination(route: route, index: index + steps)
        let last = min(index + steps, routes[route].count - 1)
        if index < last {
            target.traversedPositions = ((index + 1)...last).map { .onBoard(route: route, index: $0) }
        }
        return target
    }

    private static func destination(route: Int, index: Int) -> MoveDestination {
        if index >= routes[route].count {
            return MoveDestination(route: route, index: routes[route].count, cell: "end")
        }
        return MoveDestination(route: route, index: index, cell: routes[route][index])
    }
}
