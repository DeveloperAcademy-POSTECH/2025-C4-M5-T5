//
//  Move.swift
//  Yut
//
//  Created by Seungeun Park on 7/21/25.
//

struct MoveResult {
    let piece: PieceModel
    let cell: BoardCellModel
    let id: String
    var didGoal: Bool
}

extension BoardModel {
    func move(piece: PieceModel, steps: Int, routeIndex: Int) -> MoveResult? {
        let route = routes[routeIndex]

        // 말의 현재 위치를 찾음. 없으면 처음부터 시작
        let currentID = piece.currentCell?.id ?? route.first!
        guard let currentIndex = route.firstIndex(of: currentID) else { return nil } // 해당 셀 이름을 경로 중에 찾아 인덱스 값을 가지고 있음

        let nextIndex = currentIndex + steps

        // 도착 지점이 end 넘어가면 Goal
        if nextIndex >= route.count || route[nextIndex] == "end" {
            return MoveResult(piece: piece, cell: piece.currentCell ?? BoardCellModel(id: currentID), id: currentID, didGoal: true)
        }

        let nextID = route[nextIndex]
        guard let nextCell = cells.first(where: { $0.id == nextID }) else { return nil }

        // 이전 셀에서 나가기
        piece.currentCell?.leave(piece)

        // 다음 셀로 들어가기
        nextCell.enter(piece)
        piece.currentCell = nextCell

        return MoveResult(piece: piece, cell: nextCell, id: nextID, didGoal: false)
    }
}
