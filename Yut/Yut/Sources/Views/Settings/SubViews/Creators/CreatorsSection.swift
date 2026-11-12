import SwiftUI

struct CreatorsSection: View {
    let names: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(names, id: \.self) { name in
                Text(name).font(Typography.body)
            }
        }
        .foregroundStyle(ThemeColors.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
