//
//  GameLogicManager.swift
//  Yut
//
//  Created by yunsly on 7/21/25.
//
// 게임 로직(턴 관리, 점수 계산 등)

import Foundation
import RealityKit

class GameLogicManager {
    
    // 말을 놓을 수 있는 시작점 반환
    // 현재 규칙 상 _6_6
    func getInitialPlacementPositions() -> [String] {
        return ["_6_6"]
    }
    
    // 이동 가능한 위치들을 반환합니다. (인덱스 계산 방식)
    // - Parameters:
    //   - piece: 현재 선택된 말. `nil`이면 새로운 말을 놓는 상황입니다.
    //   - yutResult: 윷 던지기 결과 (이동할 칸 수).
    // - Returns: 이동 가능한 위치의 이름 배열
    
    func getPossibleDestinations(for piece: Entity?, yutResult: Int) -> [String] {
        
        // 새로운 말을 놓는 경우
        guard let currentPiece = piece else {
            return ["_6_6"] // 항상 시작점
        }
        
        // 기존 말을 이동하는 경우
        guard let startTileName = currentPiece.parent?.name,
              let (startRow, startCol) = parseTileName(startTileName) else {
            return []
        }
        
        var currentRow = startRow
        var currentCol = startCol
        
        // yutResult 만큼 이동을 계산합니다. (현재 위치 기준)
        for _ in 0..<yutResult {
            
            // 아래쪽 경로 (row == 6, col > 0)
            if currentRow == 6 && currentCol > 0 {
                currentCol -= 1
            }
            // 왼쪽 경로 (col == 0, row > 0)
            else if currentCol == 0 && currentRow > 0 {
                currentRow -= 1
            }
            // 위쪽 경로 (row == 0, col < 6)
            else if currentRow == 0 && currentCol < 6 {
                currentCol += 1
            }
            // 오른쪽 경로 (col == 6, row < 6)
            else if currentCol == 6 && currentRow < 6 {
                currentRow += 1
            }
            // TODO: 나중에 코너에서의 대각선 이동 로직 추가
        }

        let destination = "_\(currentRow)_\(currentCol)"
        return [destination]
    }
    
    // "_row_col" 형식의 문자열을 (Int, Int) 튜플로 파싱합니다.
    // - Parameter name: 파싱할 타일 이름
    // - Returns: (row, col) 튜플. 파싱 실패 시 nil.
    private func parseTileName(_ name: String) -> (row: Int, col: Int)? {
        let components = name.split(separator: "_")
        guard components.count == 2,
              let row = Int(components[0]),
              let col = Int(components[1]) else {
            return nil
        }
        return (row, col)
    }
    
}
