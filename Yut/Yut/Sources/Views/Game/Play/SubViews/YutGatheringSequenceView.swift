import SwiftUI

/// 준비된 첫 이미지와 레이아웃을 배치 후 유지해 버튼 입력 순간의 뷰 생성을 줄인다.
/// 숨겨진 동안에는 재생하지 않으며, 단계 변경·퇴장 시 프레임 준비 작업을 취소한다.
struct YutGatheringSequenceView: View {
    @State private var currentFrame: UIImage?
    let frames: GatheringFrameCache
    let isPlaying: Bool

    var body: some View {
        GeometryReader { geometry in
            if let image = currentFrame ?? frames.firstFrame {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width + 60, height: geometry.size.height + 60)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .ignoresSafeArea()
            }
        }
        .opacity(isPlaying ? 1 : 0)
        .accessibilityHidden(!isPlaying)
        .transaction { $0.animation = nil; $0.disablesAnimations = true }
        .task(id: isPlaying) {
            currentFrame = nil
            guard isPlaying else { return }
            frames.recordDisplayReady()
            let start = ContinuousClock.now
            var index = 1
            while index <= GatheringFrameCache.frameCount, !Task.isCancelled {
                let elapsed = start.duration(to: .now)
                let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
                index = min(GatheringFrameCache.frameCount, max(index, Int(seconds * 30) + 1))
                if let image = await frames.frame(at: index) {
                    guard !Task.isCancelled else { return }
                    currentFrame = image
                }
                do {
                    try await ContinuousClock().sleep(until: start.advanced(by: .seconds(Double(index) / 30)))
                } catch { return }
                index += 1
            }
        }
    }
}
