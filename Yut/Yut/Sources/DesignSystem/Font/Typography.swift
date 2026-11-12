import SwiftUI

/// 여러 화면에서 반복되는 글꼴만 공통 역할로 정의한다.
enum Typography {
    static let screenTitle = Font.pretendard(.semiBold, size: 28)
    static let sectionTitle = Font.pretendard(.bold, size: 24)
    static let dialogTitle = Font.pretendard(.semiBold, size: 22)
    static let button = Font.pretendard(.semiBold, size: 20)
    static let body = Font.pretendard(.medium, size: 20)
    static let instruction = Font.system(size: 18, weight: .medium)
    static let caption = Font.system(size: 15)
}
