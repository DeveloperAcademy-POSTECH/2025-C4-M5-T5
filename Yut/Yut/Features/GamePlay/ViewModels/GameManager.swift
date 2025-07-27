//
//  GameManager.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/25/25.
//

import Foundation
import RealityKit
import Foundation
import SwiftUI

enum YutResult: Int {
    case backdho = -1
    case dho = 1
    case gae = 2
    case geol = 3
    case yut = 4
    case mo = 5
    
    var steps: Int { rawValue }
    var isExtraTurn: Bool { self == .yut || self == .mo }
}

struct GameResult {
    let piece: PieceModel
    let cell: String
    var didCapture: Bool
    var didCarry: Bool
    let gameEnded: Bool
}


class GameManager :ObservableObject {
    static let shared = GameManager() // singleton
    
    // 플레이어 프로퍼티
    let players: [PlayerModel] // 플레이어 받아오기
    var currentPlayerIndex: Int = 0 // 현재 플레이어 인덱스
    var currentPlayer: PlayerModel { // 현재 플레이어
        players[currentPlayerIndex]
    }
    var pieces: [PieceModel] { // 플레이어 말들 받아오기
        players.flatMap { $0.pieces }
    }
    
    // 게임 프로퍼티
    var yutResult: YutResult? // 해피한테 윷 결과 받아오기
    var board : BoardModel = BoardModel()
    var cellStates: [String: [PieceModel]] = [:] // 각 칸 별 말 상태 저장
    @Published var result: GameResult? // 게임 최종 결과 반환
    @State private var userChooseToCarry: Bool = false
    
    func startGame() {
        currentPlayerIndex = 0
        yutResult = nil
        cellStates = [:] // 모든 칸에 있는 말 비우기
        
        for piece in pieces {
            piece.position = "_6_6"
            piece.isSelected = false
        }
    }
    
    func selectPiece(by id: UUID) { // 이건 UI 단에서 선택되는 id를 반환해야 정해질 것 같음(?) 그 UUID를 기준으로 isSelected가 true로 바뀌는 것
        for piece in pieces {
            piece.isSelected = (piece.id == id)
        }
    }
    
    func routeOptions(for piece: PieceModel, yutResult: YutResult, currentRouteIndex: Int) -> [(routeIndex: Int, destinationID: String)] { // 가능한 경로 반환
        let currentID = piece.position
        let possibleRoutes = board.availableRouteIndicate(at: currentID, currentRoute: currentRouteIndex)
        var options: [(Int, String)] = []

        for routeIndex in possibleRoutes {
            let route = board.routes[routeIndex]
            if let currentIndex = route.firstIndex(of: currentID) {
                let nextIndex = currentIndex + yutResult.steps
                if nextIndex < route.count {
                    let destinationID = route[nextIndex]
                    options.append((routeIndex, destinationID))
                }
            }
        }
        return options
    }
    
    // 경로 인덱스와 몇 칸 이동하는지 입력 받으면 그에 맞는 경로 결과 반환
    func move(piece: PieceModel, to targetCellID: String) {
        piece.position = targetCellID
    }
    
    @discardableResult
    func applyMoveResult(piece: PieceModel, to targetCellID: String) -> GameResult {
        if targetCellID == "end" || targetCellID == "start" {
            return GameResult(
                piece: piece,
                cell: targetCellID,
                didCapture: false,
                didCarry: false,
                gameEnded: true
            )
        }

        let existingPieces = cellStates[targetCellID] ?? []

        if existingPieces.isEmpty {
            cellStates[targetCellID] = [piece]
            return GameResult(
                piece: piece,
                cell: targetCellID,
                didCapture: false,
                didCarry: false,
                gameEnded: false
            )
        }

        let existingOwner = existingPieces.first!.owner
        if existingOwner === piece.owner {
            // 업기
            cellStates[targetCellID]?.append(piece)
            return GameResult(
                piece: piece,
                cell: targetCellID,
                didCapture: false,
                didCarry: true,
                gameEnded: false
            )
        } else {
            // 잡기
            for captured in existingPieces {
                // 말 리셋
            }
            cellStates[targetCellID] = [piece]
            return GameResult(
                piece: piece,
                cell: targetCellID,
                didCapture: true,
                didCarry: false,
                gameEnded: false
            )
        }
    }
    
    func nextTurn() { // 턴 돌리는 로직
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
    }
    
    func rollYut() { // TEST ONLY
        let allResults: [YutResult] = [.backdho , .dho, .gae, .geol, .yut, .mo]
        self.yutResult = allResults.randomElement()
    }
    
    func endGame() {
        // Result의 gameEnded가 true이면 게임 종료 -> 게임 결과 화면 띄우고,
    }
    
    init() {
        // TESTONLY
        let dummyEntity1 = Entity()
        let dummyEntity2 = Entity()

        let player1 = PlayerModel(name: "Player 1", sequence: 0, entities: [dummyEntity1, dummyEntity2])
        let player2 = PlayerModel(name: "Player 2", sequence: 1, entities: [dummyEntity1, dummyEntity2])

        self.players = [player1, player2]
        self.board = BoardModel()
        self.cellStates = [:]
        self.yutResult = nil
    }
}

