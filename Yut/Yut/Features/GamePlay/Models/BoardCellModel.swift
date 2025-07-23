//
//  BoardCellModel.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/18/25.
//

class BoardCellModel {
    let id: String
    private(set) var pieces: [PieceModel] = []

    init(id: String) {
        self.id = id
    }

    func enter(_ newPiece: PieceModel) {
        let sameOwner = pieces.allSatisfy { $0.owner.name == newPiece.owner.name }

        if sameOwner {
            pieces.append(newPiece)
        } else {
            for piece in pieces {
                piece.leaveCell(captured: true) // piece가 알아서 boardCell.leave(self)를 호출
            }
            pieces.removeAll()
            pieces.append(newPiece)
        }
    }

    func leave(_ piece: PieceModel) {
        if let index = pieces.firstIndex(where: { $0 === piece }) {
            pieces.remove(at: index)
        }
    }
}
