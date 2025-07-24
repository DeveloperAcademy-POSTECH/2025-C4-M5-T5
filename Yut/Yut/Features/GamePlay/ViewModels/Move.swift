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
    var cellresult : Result?
    var didGoal: Bool
}

extension BoardModel {
    func move(piece: PieceModel, steps: Int, routeIndex: Int) -> MoveResult? {
        let route = routes[routeIndex]

        let currentID = piece.currentCell?.id ?? route.first!
        guard let currentIndex = route.firstIndex(of: currentID) else { return nil }

        let nextIndex = currentIndex + steps

        if nextIndex >= route.count || route[nextIndex] == "end" {
            let emptyResult = Result(cellID: currentID, didCapture: false, didCarry: false)
            return MoveResult(
                piece: piece,
                cell: piece.currentCell ?? BoardCellModel(id: currentID),
                id: currentID,
                cellresult: emptyResult,
                didGoal: true
            )
        }


        let nextID = route[nextIndex]
        guard let nextCell = cells.first(where: { $0.id == nextID }) else { return nil }

        piece.currentCell?.leave(piece)

        let result = nextCell.enter(piece)
        piece.currentCell = nextCell

        return MoveResult(
            piece: piece,
            cell: nextCell,
            id: nextID,
            cellresult: result,
            didGoal: false
        )
    }
}

