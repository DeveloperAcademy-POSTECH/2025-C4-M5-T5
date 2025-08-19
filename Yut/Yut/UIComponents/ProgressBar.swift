import SwiftUI

/// 평면 인식 진행 상황을 시각적으로 보여주는 진행바
struct ProgressBar: View {
    let text: String
    let currentProgress: Float
    let minRequiredArea: Float
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.8))

            GeometryReader { geometry in
                let width = CGFloat(currentProgress / minRequiredArea) * geometry.size.width

                RoundedRectangle(cornerRadius: 12)
                    .fill(.white3)
                    .frame(width: width)
            }
            
            Text(text)
                .font(.system(size: 18))
                .fontWeight(.medium)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 72)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}
