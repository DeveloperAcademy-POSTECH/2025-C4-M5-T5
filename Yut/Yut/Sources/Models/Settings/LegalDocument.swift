import Foundation

struct LegalDocument: Sendable {
    enum Kind: String, Hashable, CaseIterable, Sendable {
        case termsOfService = "TermsOfService"
        case privacyPolicy = "PrivacyPolicy"

        var title: String {
            switch self {
            case .termsOfService: "이용약관"
            case .privacyPolicy: "개인정보처리방침"
            }
        }
    }

    struct Section: Identifiable, Sendable {
        let id: Int
        let title: String?
        let paragraphs: [String]
    }

    let sections: [Section]

    /// 앱에 포함된 문서를 제목·문단 단위로 나눈다. 링크·웹 실행 없이 오프라인에서 읽는다.
    init(markdown: String) {
        sections = markdown.components(separatedBy: "\n## ").enumerated().map { index, text in
            let lines = text.components(separatedBy: "\n")
            let title = index == 0 ? nil : lines.first
            let body = index == 0 ? lines.filter { !$0.hasPrefix("# ") } : Array(lines.dropFirst())
            let paragraphs = body.joined(separator: "\n").components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            return Section(id: index, title: title, paragraphs: paragraphs)
        }
    }
}
