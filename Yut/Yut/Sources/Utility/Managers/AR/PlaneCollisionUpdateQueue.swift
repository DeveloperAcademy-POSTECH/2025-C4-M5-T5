import Foundation
import simd

/// ARKit 평면의 로컬 삼각형 경계다. 앵커의 위치만 바뀐 갱신은 충돌 형상을 다시 만들지 않는다.
struct PlaneCollisionGeometry: Equatable, Sendable {
    let vertices: [SIMD3<Float>]
    let indices: [UInt32]
    let isHorizontal: Bool

    var area: Float {
        stride(from: 0, to: indices.count, by: 3).reduce(0) { area, index in
            let a = vertices[Int(indices[index])]
            let b = vertices[Int(indices[index + 1])]
            let c = vertices[Int(indices[index + 2])]
            return area + simd_length(simd_cross(b - a, c - a)) / 2
        }
    }
}

/// 평면별 최신 경계만 보관하고 충돌면 생성을 직렬 실행한다.
/// 생성 중 들어온 갱신은 다음 배치에서 처리하며, 같은 경계는 재생성하지 않는다.
@MainActor
final class PlaneCollisionUpdateQueue {
    private let interval: () -> Duration
    private let apply: (UUID, PlaneCollisionGeometry) async throws -> Void
    private let didFail: (Error) -> Void
    private var pending: [UUID: PlaneCollisionGeometry] = [:]
    private var applied: [UUID: PlaneCollisionGeometry] = [:]
    private var revisions: [UUID: UUID] = [:]
    private var processingID: UUID?
    private var worker: Task<Void, Never>?
    private var generation = UUID()

    init(
        interval: @escaping () -> Duration,
        apply: @escaping (UUID, PlaneCollisionGeometry) async throws -> Void,
        didFail: @escaping (Error) -> Void
    ) {
        self.interval = interval
        self.apply = apply
        self.didFail = didFail
    }

    func enqueue(_ geometry: PlaneCollisionGeometry, for id: UUID) {
        guard applied[id] != geometry || pending[id] != nil || processingID == id else { return }
        pending[id] = geometry
        if revisions[id] == nil { revisions[id] = UUID() }
        startWorkerIfNeeded()
    }

    /// 삭제된 평면의 이전 생성 결과가 캐시에 다시 등록되지 않도록 무효화한다.
    func remove(_ id: UUID) {
        pending[id] = nil
        applied[id] = nil
        revisions[id] = nil
    }

    /// 화면 중단 시 대기·보류 작업을 버리고, 설치된 충돌면의 캐시는 재개 시 재사용한다.
    func stop() {
        generation = UUID()
        worker?.cancel()
        processingID = nil
        pending = [:]
        revisions = [:]
    }

    func reset() {
        stop()
        applied = [:]
    }

    private func startWorkerIfNeeded() {
        guard !pending.isEmpty else { return }
        guard worker == nil else { return }
        let expectedGeneration = generation
        worker = Task { [weak self] in await self?.drain(generation: expectedGeneration) }
    }

    private func drain(generation expectedGeneration: UUID) async {
        defer {
            // 취소에 즉시 반응하지 않는 네이티브 생성 작업도 끝난 뒤 다음 작업을 시작한다.
            worker = nil
            processingID = nil
            startWorkerIfNeeded()
        }
        while !pending.isEmpty && !Task.isCancelled && generation == expectedGeneration {
            for id in Array(pending.keys) {
                guard !Task.isCancelled, generation == expectedGeneration else { return }
                guard let geometry = pending.removeValue(forKey: id), applied[id] != geometry else { continue }
                let revision = revisions[id]
                processingID = id
                do {
                    try await apply(id, geometry)
                    try Task.checkCancellation()
                    guard generation == expectedGeneration else { return }
                    if revisions[id] == revision { applied[id] = geometry }
                } catch is CancellationError {
                    if Task.isCancelled { return }
                } catch {
                    if generation == expectedGeneration { didFail(error) }
                }
                if generation == expectedGeneration { processingID = nil }
            }
            // 보류가 비어도 배치 간격을 지켜 다음 이벤트가 즉시 재생성을 시작하지 않게 한다.
            do { try await Task.sleep(for: interval()) } catch { return }
        }
    }
}
