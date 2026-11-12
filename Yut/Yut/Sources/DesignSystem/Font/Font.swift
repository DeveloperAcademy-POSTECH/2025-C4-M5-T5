//
//  Font.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/20/25.
//

import SwiftUI

extension Font {
    static func pretendard(_ weight: PretendardWeight, size: CGFloat) -> Font {
        .custom(weight.rawValue, size: size)
    }

    static func hancom(_ weight: HancomWeight, size: CGFloat) -> Font {
        .custom(weight.rawValue, size: size)
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
