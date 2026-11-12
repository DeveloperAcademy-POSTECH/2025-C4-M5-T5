//
//  YutResult+DisplayText.swift
//  Yut
//
//  Created by soyeonsoo on 7/24/25.
//

import Foundation

extension YutResult {
    var displayText: String {
        switch self {
        case .backdho: return "빽도"
        case .dho:     return "도"
        case .gae:     return "개"
        case .geol:    return "걸"
        case .yut:     return "윷"
        case .mo:      return "모"
        case .nak:     return "낙!"
        }
    }
}
