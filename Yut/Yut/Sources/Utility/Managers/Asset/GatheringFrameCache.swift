import Foundation
import OSLog
import UIKit

/// 압축 데이터는 재사용하고 시작 3장·대기 1장만 디코딩해 보관한다.
/// 나머지는 표시할 때 비동기로 준비해 전체 30장의 디코딩 메모리가 누적되지 않게 한다.
@MainActor
final class GatheringFrameCache {
    static let frameCount = 30
    private let bundle: Bundle
    private let signposter = OSSignposter(subsystem: "Yut", category: "ARPerformance")
    private var encodedFrames: [Data] = []
    private var preparedFrames: [Int: UIImage] = [:]

    var firstFrame: UIImage? { preparedFrames[1] }
    var lastFrame: UIImage? { preparedFrames[Self.frameCount] }

    init(bundle: Bundle = .main) { self.bundle = bundle }

    func prepare() async throws {
        guard encodedFrames.isEmpty else { return }
        var encoded: [Data] = []
        var prepared: [Int: UIImage] = [:]
        for index in 1...Self.frameCount {
            try Task.checkCancellation()
            guard let url = bundle.url(forResource: String(format: "Yut.%04d", index), withExtension: "png") else {
                throw CocoaError(.fileReadNoSuchFile)
            }
            let data = try Data(contentsOf: url)
            encoded.append(data)
            if index <= 3 || index == Self.frameCount {
                guard let image = UIImage(data: data), let displayImage = await image.byPreparingForDisplay() else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                prepared[index] = displayImage
            }
        }
        try Task.checkCancellation()
        encodedFrames = encoded
        preparedFrames = prepared
    }

    func frame(at index: Int) async -> UIImage? {
        if let cached = preparedFrames[index] { return cached }
        guard encodedFrames.indices.contains(index - 1), let image = UIImage(data: encodedFrames[index - 1]) else { return nil }
        return await image.byPreparingForDisplay()
    }

    func recordDisplayReady() { signposter.emitEvent("GatherViewReady") }

    func clear() {
        encodedFrames = []
        preparedFrames = [:]
    }
}
