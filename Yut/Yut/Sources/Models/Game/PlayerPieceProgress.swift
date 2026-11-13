import Foundation

/// 확정 스냅샷에서 매번 계산하는 표시 값이다. 상태별 개수를 별도로 저장하지 않는다.
struct PlayerPieceProgress: Identifiable {
    let id: UUID
    let name: String
    let order: Int
    let isCurrent: Bool
    let isLocal: Bool
    let positions: [PiecePosition]

    var waitingNumbers: [Int] { positions.indices.filter { positions[$0] == .home }.map { $0 + 1 } }
    var movingNumbers: [Int] {
        positions.indices.filter { index in
            if case .onBoard = positions[index] { return true }
            return false
        }.map { $0 + 1 }
    }
    var finishedNumbers: [Int] { positions.indices.filter { positions[$0] == .finished }.map { $0 + 1 } }
}
