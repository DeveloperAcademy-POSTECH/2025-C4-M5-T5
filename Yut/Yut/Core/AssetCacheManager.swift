import RealityKit

class AssetCacheManager {
    // MARK: - 캐시 저장소
    private var cache: [String: ModelEntity] = [:]

    // MARK: - 고정된 에셋 목록 (내부 정의)
    private let predefinedAssets: [String] = [
        "Yut1",
        "Yut2",
        "Yut3",
        "Yut4_back",
        "Board",
        "Piece1_yellow",
        "Piece2_jade",
        "Piece3_red",
        "Piece4_blue"
    ]

    // MARK: - 전체 에셋 한 번에 preload
    func preloadAll() async {
        await preload(names: predefinedAssets)
    }

    // MARK: - 선택 preload (내부 전용 호출에도 사용됨)
    func preload(names: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for name in names {
                group.addTask {
                    if self.cache[name] == nil {
                        if let entity = try? await ModelEntity(named: name) {
                            self.cache[name] = entity
                        }
                    }
                }
            }
        }
    }

    // MARK: - 캐시된 모델 로드
    func load(named name: String) async throws -> ModelEntity {
        if let cached = cache[name] {
            return await cached.clone(recursive: true)
        }

        let entity = try await ModelEntity(named: name)
        cache[name] = entity
        return await entity.clone(recursive: true)
    }
    
    // MARK: - 외부에서 캐시된 모델 조회 (clone 없이 원본)
    func cachedModel(named name: String) -> ModelEntity? {
        return cache[name]
    }

    // MARK: - 캐시 초기화
    func clearCache() {
        cache.removeAll()
    }
}
