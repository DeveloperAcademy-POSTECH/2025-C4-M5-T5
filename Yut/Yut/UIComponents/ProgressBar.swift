import SwiftUI

/// 평면 인식 진행 상황을 시각적으로 보여주는 진행바
struct ProgressBar: View {
    // 안내 문구 (예: "바닥을 충분히 색칠해 주세요.")
    let text: String
    // 현재 인식된 면적 (예: 8)
    let currentProgress: Float
    // 요구되는 최소 면적 (예: 15)
    let minRequiredArea: Float
    
    var body: some View {
        ZStack(alignment: .leading) {
            // 전체 배경 바 (진행률과 관계없는 틀)
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.8)) // 흐린 반투명 재질

            // 실제 진행률을 나타내는 채워지는 바
            GeometryReader { geometry in
                // 현재 진행률 비율 계산
                let width = CGFloat(currentProgress / minRequiredArea) * geometry.size.width

                RoundedRectangle(cornerRadius: 12)
                    .fill(.white3) // 사용자 정의 색상
                    .frame(width: width) // 진행된 비율만큼 너비 지정
            }

            // 가운데 표시되는 안내 텍스트
            Text(text)
                .font(.system(size: 18))
                .fontWeight(.medium)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity) // 가운데 정렬
        }
        .frame(height: 72)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

//#Preview {
//    ProgressBar(
//        text: "바닥을 충분히 색칠해주세요",
//        currentProgress: 8,
//        minRequiredArea: 15
//    )
//}
