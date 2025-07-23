//
//  Font.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/20/25.
//

import SwiftUI

/* 사용예시
     .font(.pretendard(.semiBold, size: 22))

     .font(.hancom(.hoonmin, size: 24))

     .font(.PR.largeTitle1B)
 */

extension Font {
    static func pretendard(_ weight: PretendardWeight, size: CGFloat) -> Font {
        .custom(weight.rawValue, size: size)
    }

    static func hancom(_ weight: HancomWeight, size: CGFloat) -> Font {
        .custom(weight.rawValue, size: size)
    }

    enum PR {
        static let largeTitle1B = Font.custom("Pretendard-Bold", size: 34)
        static let largeTitle2 = Font.custom("Pretendard-Medium", size: 28)
        static let largeTitle3B = Font.custom("Pretendard-Bold", size: 24)
        static let title = Font.custom("Pretendard-Medium", size: 20)
        static let titleB = Font.custom("Pretendard-Bold", size: 18)
    }
}

enum PretendardWeight: String {
    case regular = "Pretendard-Regular"
    case medium = "Pretendard-Medium"
    case semiBold = "Pretendard-SemiBold"
    case bold = "Pretendard-Bold"
    case extraBold = "Pretendard-ExtraBold"
}

enum HancomWeight: String {
    case hoonmin = "HancomHoonminjeongeumH"
}
