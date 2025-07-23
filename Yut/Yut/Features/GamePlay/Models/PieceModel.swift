//
//  TokenModel.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/17/25.
//

import Foundation

class PieceModel {
    var id : UUID = UUID()
    var currentCell: BoardCellModel?
    var isSeleted: Bool = false
    var owner: PlayerModel
    
    init(owner: PlayerModel){
        self.owner = owner
    }
    
    func leaveCell(captured: Bool) {
        currentCell?.leave(self)
        currentCell = nil

        if captured {
            // 말이 잡혔을 경우 _6_6으로 이동
//            if let startCell = GameManager.shared.board.cell(withID: "_6_6") {
//                startCell.enter(self)
//                currentCell = startCell
//            }

        }
    }

}


