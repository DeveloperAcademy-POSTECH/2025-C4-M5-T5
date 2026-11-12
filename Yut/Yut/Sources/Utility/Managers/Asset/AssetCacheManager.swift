import RealityKit

/// 원본 ModelEntity 로더와 템플릿을 유지하며, 준비 실패를 호출자에게 전달한다.
@MainActor
final class AssetCacheManager {
    let gatheringFrames = GatheringFrameCache()
    private(set) var boardTemplate: Entity?
    private var cache: [String: ModelEntity] = [:]
    private let names = ["Yut1", "Yut2", "Yut3", "Yut4_back", "Piece1_yellow", "Piece2_jade", "Piece3_blue", "Piece4_red"]

    func preloadAll() async throws {
        try await gatheringFrames.prepare()
        if boardTemplate == nil {
            // ModelEntity 로더는 계층을 평탄화하므로 칸·골인 이름을 유지하는 Entity 로더를 쓴다.
            let board = try await Entity(named: "Board")
            try Task.checkCancellation()
            boardTemplate = board
        }
        for name in names where cache[name] == nil {
            let model = try await ModelEntity(named: name)
            try Task.checkCancellation()
            cache[name] = model
        }
    }

    func cachedModel(named name: String) -> ModelEntity? { cache[name] }
    func clearCache() {
        cache = [:]
        boardTemplate = nil
        gatheringFrames.clear()
    }
}
