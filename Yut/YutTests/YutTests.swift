//
//  YutTests.swift
//  YutTests
//
//  Created by Jay on 7/11/25.
//

import Testing
import RealityKit
import SwiftUI
import Foundation
import ARKit

@testable import Yut

struct YutTests {
//    @Test func example() async throws {
//        let boardmodel = BoardModel()
//        let result = boardmodel.availableRouteIndicate(at: "_2_6", currentRoute: 0)
//        print(result)
//    }
    
//    @Test func example() async throws {
//        let gamemanager = GameManager.shared.startGame()
//        let result = gamemanager.routeOptions(for: <#T##PieceModel#>, yutResult: <#T##YutResult#>, currentRouteIndex: <#T##Int#>)
//        print(result)
//    }
    
//    @Test func example() async throws {
//        let gameManager = GameManager.shared
//        gameManager.startGame()
//
//        guard let testPiece = gameManager.players.first?.pieces.first else {
//            XCTFail("Piece가 없습니다.")
//            return
//        }
//
//        testPiece.position = "_4_6" // 경로 상 존재하는 위치
//
//        let result = gameManager.routeOptions(
//            for: testPiece,
//            yutResult: .gae,
//            currentRouteIndex: 0
//        )
//
//        print("routeOptions result: \(result)")
//    }
    
//    @Test func example() async throws {
//        let gameManager = GameManager.shared
//        gameManager.startGame()
//
//        guard let testPiece = gameManager.players.first?.pieces.first else {
//            XCTFail("Piece가 없습니다.")
//            return
//        }
//
//        testPiece.position = "_4_6" // 경로 상 존재하는 위치
//
//        gameManager.move(piece: testPiece,to : "_2_6")
//
//        print("position: \(testPiece.position)")
//    }
    
//    @Test func example() async throws {
//        let gameManager = GameManager.shared
//        gameManager.startGame()
//
//        let player1 = gameManager.players[0]
//        let player2 = gameManager.players[1]
//
//        guard player1.pieces.count >= 2 else {
//            XCTFail("Player 1의 말이 2개 이상 있어야 합니다.")
//            return
//        }
//
//        let testPiece1 = player1.pieces[0]
//        let testPiece2 = player1.pieces[1]
//
//        guard let testPiece3 = player2.pieces.first else {
//            XCTFail("Player 2의 말이 하나 이상 있어야 합니다.")
//            return
//        }
//
//        gameManager.cellStates["_2_6"] = [testPiece1]
//        gameManager.cellStates["_1_6"] = [testPiece3]
//
//        let result = gameManager.applyMoveResult(piece: testPiece2, to: "_0_6", userChooseToCarry: false)
//        let result2 = testPiece3.position
//
//        print(result2)
//
//        if let updated = gameManager.cellStates["_2_6"] {
//            print("2_6에 있는 말 개수: \(updated.count)")
//            for piece in updated {
//                print(" - pieceID: \(piece.id), owner: \(piece.owner.name)")
//            }
//        } else {
//            print("2_6 칸은 비어 있습니다.")
//        }
//    }
    
//    @Test func testNextTurnRotation() async throws {
//        let gameManager = GameManager.shared
//        gameManager.startGame()
//
//        let totalPlayers = 4
//        var seenIndices: [Int] = []
//
//        for _ in 0..<(totalPlayers * 2) { // 두 바퀴 돌기
//            seenIndices.append(gameManager.currentPlayerIndex)
//            gameManager.nextTurn()
//        }
//
//        let expected = Array(0..<totalPlayers) + Array(0..<totalPlayers)
//
//        print(expected)
//    }
}

