//
//  GameManager.swift
//  GameLogic
//
//  Created by Seungeun Park on 7/25/25.
//

import Foundation
import MultipeerConnectivity
import RealityKit
import SwiftUI

enum YutResult: Int, Identifiable, CaseIterable {
    case backdho = -1
    case nak = 0
    case dho = 1
    case gae = 2
    case geol = 3
    case yut = 4
    case mo = 5
    
    var steps: Int { rawValue }
    // 추가 턴
    var isExtraTurn: Bool { self == .yut || self == .mo }
    
    // ForEach를 위한 id
    var id: Int { rawValue }
}

struct GameResult {
    let piece: PieceModel
    let cell: String
    var didCapture: Bool
    var capturedPieces: [PieceModel] // 잡힌 말 목록을 전달하기 위해 추가
    var didCarry: Bool
    let gameEnded: Bool
}

class GameManager :ObservableObject {
    static let shared = GameManager() // singleton
    
    // 플레이어 프로퍼티
    @Published var players: [PlayerModel] = []
    var currentPlayerIndex: Int = 0
    var currentPlayer: PlayerModel {
        players[currentPlayerIndex]
    }
    var pieces: [PieceModel] {
        players.flatMap { $0.pieces }
    }
    
    // 게임 프로퍼티
    var yutResult: YutResult?
    var board : BoardModel = BoardModel()
    var cellStates: [String: [PieceModel]] = [:] // 각 칸 별 말 상태 저장
    @Published var result: GameResult? // 게임 최종 결과 반환
    @State private var userChooseToCarry: Bool = false // 업을지 말지 여부 상태 변수
    
    // currentPlayer의 말 중에 position이 "_6_6"인 것이 하나라도 있는지 확인
    var currentPlayerHasOffBoardPieces: Bool {
        
        currentPlayer.pieces.contains { $0.position == "_6_6" }
    }
    
    func startGame(with players: [PlayerModel]) {
        self.players = players
        currentPlayerIndex = 0
        yutResult = nil
        cellStates = [:] // 모든 칸에 있는 말 비우기
        
        for piece in pieces {
            piece.position = "_6_6" // PieceModel의 기본값이지만 명시적으로 설정
            piece.isSelected = false
            piece.routeIndex = 0 // 기본 경로로 설정
        }
        print("✅ GameManager: 새로운 게임이 \(players.count)명의 플레이어와 함께 설정되었습니다.")
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
                } else if (nextIndex < 0){
                    let destinationID = "start"
                    options.append((routeIndex, destinationID))
                } else {
                    let destinationID = "end"
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
    func applyMoveResult(piece: PieceModel, to targetCellID: String, userChooseToCarry: Bool) -> GameResult {
        if targetCellID == "end" {
            return GameResult(
                piece: piece,
                cell: "_6_6",
                didCapture: false,
                capturedPieces: [],
                didCarry: false,
                gameEnded: true
            )
        } else if (targetCellID == "start") {
            return GameResult(
                piece: piece,
                cell: "_5_6",
                didCapture: false,
                capturedPieces: [],
                didCarry: false,
                gameEnded: true
            )
        }
        
        let existingPieces = cellStates[targetCellID] ?? []
        
        // 1. 해당 칸에 아무도 없을 때
        if existingPieces.isEmpty {
            // 이전 위치에서 말 제거
            if let previousPieces = cellStates[piece.position],
               let index = previousPieces.firstIndex(where: { $0.id == piece.id }) {
                cellStates[piece.position]?.remove(at: index)
            }
            // 새 위치에 말 추가
            cellStates[targetCellID] = [piece]
            piece.position = targetCellID
            
            return GameResult(
                piece: piece,
                cell: targetCellID,
                didCapture: false,
                capturedPieces: [],
                didCarry: false,
                gameEnded: false
            )
        }
        
        // 2. 해당 칸에 다른 말이 있을 때
        let existingOwner = existingPieces.first!.owner
        
        // 2-1. 내 말일 경우 (업거나, 따로 가거나)
        if existingOwner === piece.owner {
            if let previousPieces = cellStates[piece.position],
                let index = previousPieces.firstIndex(where: { $0.id == piece.id }) {
                cellStates[piece.position]?.remove(at: index)
            }

            cellStates[targetCellID]?.append(piece)
            piece.position = targetCellID
            
            return GameResult(
                piece: piece,
                cell: targetCellID,
                didCapture: false,
                capturedPieces: [],
                didCarry: userChooseToCarry,
                gameEnded: false
            )
        }
        // 2-2. 상대 말일 경우 (잡기)
        else {
            if let previousPieces = cellStates[piece.position],
                let index = previousPieces.firstIndex(where: { $0.id == piece.id }) {
                cellStates[piece.position]?.remove(at: index)
            }
            
            // 잡힌 말들의 위치를 _6_6으로 초기화
            for capturedPiece in existingPieces {
                capturedPiece.position = "_6_6"
                capturedPiece.routeIndex = 0 // 경로도 초기화
            }

            cellStates[targetCellID] = [piece]
            piece.position = targetCellID
            
            return GameResult(
                piece: piece,
                cell: targetCellID,
                didCapture: true,
                capturedPieces: existingPieces,
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
        // TODO: Result의 gameEnded가 true이면 게임 종료 -> 게임 결과 화면 띄우고,
    }
}
