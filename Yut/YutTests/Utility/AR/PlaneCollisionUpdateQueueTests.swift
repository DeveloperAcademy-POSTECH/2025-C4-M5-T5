import Foundation
import Testing
@testable import Yut

@MainActor
struct PlaneCollisionUpdateQueueTests {
    private enum TestError: Error { case timeout, unavailable }

    @Test
    func resumeWaitsForCancelledGenerationBeforeStartingNext() async throws {
        let id = UUID()
        var applied: [PlaneCollisionGeometry] = []
        var continuation: CheckedContinuation<Void, Never>?
        var concurrent = 0
        var maximumConcurrent = 0
        let queue = PlaneCollisionUpdateQueue(interval: { .milliseconds(1) }, apply: { _, geometry in
            concurrent += 1
            maximumConcurrent = max(maximumConcurrent, concurrent)
            applied.append(geometry)
            if applied.count == 1 { await withCheckedContinuation { continuation = $0 } }
            concurrent -= 1
        }, didFail: { Issue.record($0) })
        defer { continuation?.resume(); queue.stop() }
        queue.enqueue(geometry(1), for: id)
        try await waitUntil { continuation != nil }
        queue.stop()
        queue.enqueue(geometry(2), for: id)
        try await Task.sleep(for: .milliseconds(30))
        #expect(applied == [geometry(1)])
        continuation?.resume()
        continuation = nil
        try await waitUntil { applied.count == 2 }
        #expect(maximumConcurrent == 1)
        #expect(applied.last == geometry(2))
    }

    @Test
    func identicalUpdatesGenerateOneCollisionSurface() async throws {
        let id = UUID()
        var applied: [PlaneCollisionGeometry] = []
        let queue = PlaneCollisionUpdateQueue(interval: { .milliseconds(10) }, apply: { _, geometry in
            applied.append(geometry)
        }, didFail: { Issue.record($0) })
        defer { queue.stop() }
        for _ in 0..<100 { queue.enqueue(geometry(1), for: id) }
        try await waitUntil { applied.count == 1 }
        for _ in 0..<100 { queue.enqueue(geometry(1), for: id) }
        try await Task.sleep(for: .milliseconds(40))
        #expect(applied == [geometry(1)])
    }

    @Test
    func updatesDuringGenerationKeepLatestGeometryAndRunSerially() async throws {
        let id = UUID()
        var applied: [PlaneCollisionGeometry] = []
        var continuation: CheckedContinuation<Void, Never>?
        var concurrent = 0
        var maximumConcurrent = 0
        let queue = PlaneCollisionUpdateQueue(interval: { .milliseconds(1) }, apply: { _, geometry in
            concurrent += 1
            maximumConcurrent = max(maximumConcurrent, concurrent)
            applied.append(geometry)
            if applied.count == 1 { await withCheckedContinuation { continuation = $0 } }
            concurrent -= 1
        }, didFail: { Issue.record($0) })
        defer { continuation?.resume(); queue.stop() }
        queue.enqueue(geometry(1), for: id)
        try await waitUntil { continuation != nil }
        for value in 2...100 { queue.enqueue(geometry(Float(value)), for: id) }
        continuation?.resume()
        continuation = nil
        try await waitUntil { applied.count == 2 }
        #expect(applied == [geometry(1), geometry(100)])
        #expect(maximumConcurrent == 1)
    }

    @Test
    func returningToPreviousGeometryIsNotLostWhileAnotherIsBuilding() async throws {
        let id = UUID()
        var applied: [PlaneCollisionGeometry] = []
        var continuation: CheckedContinuation<Void, Never>?
        let queue = PlaneCollisionUpdateQueue(interval: { .milliseconds(1) }, apply: { _, geometry in
            applied.append(geometry)
            if applied.count == 2 { await withCheckedContinuation { continuation = $0 } }
        }, didFail: { Issue.record($0) })
        defer { continuation?.resume(); queue.stop() }
        queue.enqueue(geometry(1), for: id)
        try await waitUntil { applied.count == 1 }
        queue.enqueue(geometry(2), for: id)
        try await waitUntil { continuation != nil }
        queue.enqueue(geometry(1), for: id)
        continuation?.resume()
        continuation = nil
        try await waitUntil { applied.count == 3 }
        #expect(applied == [geometry(1), geometry(2), geometry(1)])
    }

    @Test
    func removedPlaneDoesNotRestoreItsOldCache() async throws {
        let id = UUID()
        var count = 0
        var continuation: CheckedContinuation<Void, Never>?
        let queue = PlaneCollisionUpdateQueue(interval: { .milliseconds(1) }, apply: { _, _ in
            count += 1
            if count == 1 { await withCheckedContinuation { continuation = $0 } }
        }, didFail: { Issue.record($0) })
        defer { continuation?.resume(); queue.stop() }
        queue.enqueue(geometry(1), for: id)
        try await waitUntil { continuation != nil }
        queue.remove(id)
        continuation?.resume()
        continuation = nil
        queue.enqueue(geometry(1), for: id)
        try await waitUntil { count == 2 }
    }

    @Test
    func failureCanRetrySameGeometry() async throws {
        let id = UUID()
        var attempts = 0
        var failures = 0
        let queue = PlaneCollisionUpdateQueue(interval: { .milliseconds(1) }, apply: { _, _ in
            attempts += 1
            if attempts == 1 { throw TestError.unavailable }
        }, didFail: { _ in failures += 1 })
        defer { queue.stop() }
        queue.enqueue(geometry(1), for: id)
        try await waitUntil { failures == 1 }
        queue.enqueue(geometry(1), for: id)
        try await waitUntil { attempts == 2 }
        #expect(failures == 1)
    }

    @Test
    func stoppingDropsPendingWorkAndResetAllowsRebuilding() async throws {
        let id = UUID()
        var applied: [PlaneCollisionGeometry] = []
        let queue = PlaneCollisionUpdateQueue(interval: { .milliseconds(10) }, apply: { _, geometry in
            applied.append(geometry)
        }, didFail: { Issue.record($0) })
        defer { queue.stop() }
        queue.enqueue(geometry(1), for: id)
        try await waitUntil { applied.count == 1 }
        queue.enqueue(geometry(2), for: id)
        queue.stop()
        try await Task.sleep(for: .milliseconds(30))
        #expect(applied == [geometry(1)])
        queue.reset()
        queue.enqueue(geometry(1), for: id)
        try await waitUntil { applied.count == 2 }
    }

    private func geometry(_ width: Float) -> PlaneCollisionGeometry {
        PlaneCollisionGeometry(vertices: [[0, 0, 0], [width, 0, 0], [0, 0, 1]], indices: [0, 1, 2], isHorizontal: true)
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<100 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        throw TestError.timeout
    }
}
