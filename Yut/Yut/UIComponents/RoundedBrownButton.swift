import SwiftUI

/// 둥근 모서리를 가진 커스텀 갈색 버튼 컴포넌트
struct RoundedBrownButton: View {
    // 버튼에 표시될 텍스트
    let title: String
    // 버튼 활성화 여부
    let isEnabled: Bool
    // 버튼 클릭 시 실행될 액션
    let action: () -> Void

    var body: some View {
        Button(action: {
            // 버튼이 활성화된 경우에만 액션 실행
            if isEnabled {
                action()
            }
        }) {
            // 버튼 내부 텍스트 스타일 설정
            Text(title)
                .foregroundColor(.white) // 글자색 흰색
                .font(.headline)
                .padding(.vertical, 12) // 세로 여백
                .frame(maxWidth: .infinity) // 너비 최대
                .frame(height: 70) // 고정 높이
                .background(
                    isEnabled
                    ? Color(red: 56/255, green: 40/255, blue: 33/255) // 갈색
                    : Color.gray // 비활성화 시 회색
                )
                .cornerRadius(24) // 모서리 둥글게
        }
        .padding(.horizontal, 20) // 좌우 여백
        .disabled(!isEnabled) // 버튼 비활성화 처리
    }
}
