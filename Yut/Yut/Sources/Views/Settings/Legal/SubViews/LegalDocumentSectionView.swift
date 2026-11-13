import SwiftUI

struct LegalDocumentSectionView: View {
    let section: LegalDocument.Section

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title = section.title {
                Text(title).font(Typography.sectionTitle).accessibilityAddTraits(.isHeader)
            }
            ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph).font(Typography.body).lineSpacing(6)
            }
        }
        .foregroundStyle(ThemeColors.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }
}
