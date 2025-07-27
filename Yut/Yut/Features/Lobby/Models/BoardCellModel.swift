//
//  BoardCellModel.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/18/25.
//

struct Result {
    var cellID: String       // 말이 들어간 셀의 ID
    var didCapture: Bool     // 잡았는지 여부
    var didCarry: Bool       // 업었는지 여부
}

class BoardCellModel {
    let id: String
    private(set) var pieces: [PieceModel] = []

    init(id: String) {
        self.id = id
    }

    @discardableResult
    func enter(_ newPiece: PieceModel) -> Result {
        let cellID = self.id

        if pieces.isEmpty {
            pieces.append(newPiece)
            return Result(cellID: cellID, didCapture: false, didCarry: false)
        }

        let existingOwner = pieces.first!.owner.name

        if existingOwner == newPiece.owner.name {
            // 업기
            pieces.append(newPiece)
            return Result(cellID: cellID, didCapture: false, didCarry: true)
        } else {
            // 잡기
            for piece in pieces {
                piece.leaveCell(captured: true)
            }
            pieces.removeAll()
            pieces.append(newPiece)
            return Result(cellID: cellID, didCapture: true, didCarry: false)
        }
    }

    func leave(_ piece: PieceModel) {
        if let index = pieces.firstIndex(where: { $0 === piece }) {
            pieces.remove(at: index)
        }
    }
}
