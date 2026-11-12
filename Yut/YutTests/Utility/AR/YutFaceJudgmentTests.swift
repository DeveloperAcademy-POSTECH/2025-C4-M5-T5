import AVFoundation
import Foundation
import RealityKit
import simd
import Testing
@testable import Yut

@MainActor
@Suite(.serialized)
struct YutFaceJudgmentTests {
    @Test
    func sameWorldFacingKeepsResultWhenParentRollChanges() async throws {
        let coordinator = makeCoordinator()
        let parents = [simd_quatf(angle: .pi / 2, axis: [0, 0, 1]), simd_quatf(angle: -.pi / 2, axis: [0, 0, 1])]
        for parentRotation in parents {
            let hierarchy = makeHierarchy(flatSidesUp: [false, false, false, false], parentRotation: parentRotation)
            let models = hierarchy.models
            defer { withExtendedLifetime(hierarchy.root) {} }
            // 월드에서 네 둥근 면이 위라는 조건은 부모 회전과 무관하게 고정한다.
            for model in models {
                let worldNormal = model.entity.orientation(relativeTo: nil).act(SIMD3<Float>(0, 1, 0))
                #expect(simd_distance(worldNormal, SIMD3<Float>(0, 1, 0)) < 0.00001)
            }
            let result = try await evaluate(models, with: coordinator)
            #expect(result == .mo)
        }
    }

    @Test(arguments: 0..<16)
    func allVisibleFaceCombinationsIgnoreCameraAndAncestorRotations(mask: Int) async throws {
        let flatSidesUp = (0..<4).map { mask & (1 << $0) != 0 }
        let count = flatSidesUp.filter { $0 }.count
        let expected: YutResult
        switch count {
        case 0: expected = .mo
        case 1: expected = flatSidesUp[3] ? .backdho : .dho
        case 2: expected = .gae
        case 3: expected = .geol
        default: expected = .yut
        }
        let rotations = [
            simd_quatf(angle: 0, axis: [0, 1, 0]),
            simd_quatf(angle: .pi / 2, axis: [0, 0, 1]),
            simd_quatf(angle: -.pi / 2, axis: [0, 0, 1]),
            simd_quatf(angle: .pi / 3, axis: [1, 0, 0]),
            simd_quatf(angle: .pi, axis: [0, 1, 0]),
            simd_quatf(angle: -.pi / 4, axis: simd_normalize(SIMD3<Float>(1, 2, 3)))
        ]
        let coordinator = makeCoordinator()
        for parentRotation in rotations {
            let hierarchy = makeHierarchy(flatSidesUp: flatSidesUp, parentRotation: parentRotation)
            defer { withExtendedLifetime(hierarchy.root) {} }
            let models = hierarchy.models
            #expect(try await evaluate(models, with: coordinator) == expected)
            #expect(models.indices.allSatisfy { coordinator.yutManager.thrownYuts[$0].isFrontUp == !flatSidesUp[$0] })
        }
    }

    @Test
    func tiltedVisibleFacesKeepTheirResultAcrossHeadingAndQuaternionSign() async throws {
        let coordinator = makeCoordinator()
        for heading in [Float(0), .pi / 2, .pi, -.pi / 3] {
            let worldRotation = simd_quatf(angle: heading, axis: [0, 1, 0]) * simd_quatf(angle: .pi / 6, axis: [0, 0, 1])
            let hierarchy = makeHierarchy(flatSidesUp: [false, false, false, true], parentRotation: simd_quatf(angle: .pi / 3, axis: [1, 0, 0]))
            let models = hierarchy.models
            defer { withExtendedLifetime(hierarchy.root) {} }
            for (index, model) in models.enumerated() {
                let flip = simd_quatf(angle: index == 3 ? .pi : 0, axis: [0, 0, 1])
                let orientation = worldRotation * flip
                model.entity.setOrientation(simd_quatf(vector: -orientation.vector), relativeTo: nil)
            }
            #expect(try await evaluate(models, with: coordinator) == .backdho)
        }
    }

    @Test
    func bundledModelsUseSameFacingAndBackDoIdentity() async throws {
        let coordinator = makeCoordinator()
        let parent = Entity()
        defer { withExtendedLifetime(parent) {} }
        parent.orientation = simd_quatf(angle: .pi / 3, axis: [0, 1, 0]) * simd_quatf(angle: .pi / 4, axis: [1, 0, 0])
        var models: [YutModel] = []
        for name in ["Yut1", "Yut2", "Yut3", "Yut4_back"] {
            let url = try #require(Bundle.main.url(forResource: name, withExtension: "usdz"))
            let entity = try await ModelEntity(contentsOf: url)
            parent.addChild(entity)
            entity.setOrientation(simd_quatf(angle: 0, axis: [0, 0, 1]), relativeTo: nil)
            models.append(YutModel(entity: entity))
        }
        #expect(models[3].entity.name == "Yut_4_back")
        #expect(try await evaluate(models, with: coordinator) == .mo)
        models[3].entity.setOrientation(simd_quatf(angle: .pi, axis: [0, 0, 1]), relativeTo: nil)
        #expect(try await evaluate(models, with: coordinator) == .backdho)
        for model in models { model.entity.setOrientation(simd_quatf(angle: .pi, axis: [0, 0, 1]), relativeTo: nil) }
        #expect(try await evaluate(models, with: coordinator) == .yut)
    }

    private func makeCoordinator() -> ARCoordinator {
        ARCoordinator(state: ARState(gameManager: GameManager()), assets: AssetCacheManager(),
            sound: SoundService(audioSession: AVAudioSession.sharedInstance()))
    }

    private func makeHierarchy(flatSidesUp: [Bool], parentRotation: simd_quatf) -> (root: Entity, models: [YutModel]) {
        let ancestor = Entity()
        ancestor.orientation = simd_quatf(angle: .pi / 7, axis: [0, 1, 0])
        let parent = Entity()
        parent.orientation = parentRotation
        ancestor.addChild(parent)
        let models = flatSidesUp.enumerated().map { index, flatSideUp in
            let entity = ModelEntity()
            entity.name = index == 3 ? "Yut_4_back" : "Yut_\(index + 1)"
            parent.addChild(entity)
            entity.setOrientation(simd_quatf(angle: flatSideUp ? .pi : 0, axis: [0, 0, 1]), relativeTo: nil)
            return YutModel(entity: entity)
        }
        return (ancestor, models)
    }

    private func evaluate(_ models: [YutModel], with coordinator: ARCoordinator) async throws -> YutResult {
        coordinator.arState.yutResult = nil
        coordinator.yutManager.thrownYuts = models
        coordinator.yutManager.evaluateYuts()
        for _ in 0..<20 {
            if let result = coordinator.arState.yutResult { return result }
            await Task.yield()
        }
        return try #require(coordinator.arState.yutResult)
    }
}
