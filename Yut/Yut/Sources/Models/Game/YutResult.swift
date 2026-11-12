import Foundation

enum YutResult: Int, Identifiable, CaseIterable, Codable, Sendable {
    case backdho = -1
    case nak = 0
    case dho = 1
    case gae = 2
    case geol = 3
    case yut = 4
    case mo = 5
    
    var steps: Int { rawValue }
    var moveCount: Int { rawValue }
    var grantsAnotherThrow: Bool { isExtraTurn }
    // 추가 턴
    var isExtraTurn: Bool { self == .yut || self == .mo }
    
    // ForEach를 위한 id
    var id: Int { rawValue }
}

