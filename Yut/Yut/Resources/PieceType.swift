//
//  Player.swift
//  Yut
//
//  Created by soyeonsoo on 7/27/25.
//

// PieceType.swift

import SwiftUI

enum PieceType: CaseIterable, Equatable {
    case yellow, jade, blue, red

    var imageName: String {
        switch self {
        case .yellow: return "piece1_yellow"
        case .jade: return "piece2_jade"
        case .blue: return "piece3_blue"
        case .red: return "piece4_red"
        }
    }

    var sequence: Int {
        switch self {
        case .yellow: return 1
        case .jade: return 2
        case .blue: return 3
        case .red: return 4
        }
    }

    static func from(imageName: String) -> PieceType? {
        allCases.first { $0.imageName == imageName }
    }

    static func from(sequence: Int) -> PieceType? {
        allCases.first { $0.sequence == sequence }
    }
}

extension PieceType {
    var backgroundColor: Color {
        switch self {
        case .yellow: return Color("piece_yellow")
        case .jade: return Color("piece_jade")
        case .blue: return Color("piece_blue")
        case .red: return Color("piece_red")
        }
    }

    var textColor: Color {
        switch self {
        case .blue: return .white1
        default: return .brown1
        }
    }
}
