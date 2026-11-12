//
//  PieceType.swift
//  Yut
//
//  Created by soyeonsoo on 7/27/25.
//


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
