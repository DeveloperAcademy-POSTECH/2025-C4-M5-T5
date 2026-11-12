import SwiftUI

/// 원본 30장·30fps 연출을 사용하며 화면이 사라지면 프레임 준비 작업도 취소한다.
struct YutGatheringSequenceView: View {
    @State private var currentFrame: UIImage?
    let frames: GatheringFrameCache
    @Binding var isAnimationDone: Bool

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
        .task {
            isAnimationDone = false
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
            if !Task.isCancelled { isAnimationDone = true }
        }
    }
}
