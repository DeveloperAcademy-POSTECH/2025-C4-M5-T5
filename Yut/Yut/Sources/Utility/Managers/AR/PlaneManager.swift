import ARKit
import Combine
import OSLog
import RealityKit

/// 같은 평면의 갱신을 합치고, 새 충돌면이 준비될 때까지 기존 충돌면을 유지한다.
@MainActor
final class PlaneManager {
    var scene: Scene?
    private let logger = Logger(subsystem: "Yut", category: "Plane")
    private let signposter = OSSignposter(subsystem: "Yut", category: "ARPerformance")
    private let recognizedAreaSubject = CurrentValueSubject<Float, Never>(0)
    private var showsVisualization = true
    private var visualizationColor = UIColor(named: "white1") ?? .white
    private var isRunning = true
    private var planeEntities: [UUID: ModelEntity] = [:]
    private var geometries: [UUID: PlaneCollisionGeometry] = [:]
    private var planeAreas: [UUID: Float] = [:]
    private lazy var updates = PlaneCollisionUpdateQueue(
        interval: {
            switch ProcessInfo.processInfo.thermalState {
            case .serious, .critical: .seconds(1)
            case .fair: .milliseconds(500)
            default: .milliseconds(250)
            }
        },
        apply: { [weak self] id, geometry in try await self?.apply(geometry, for: id) },
        didFail: { [weak self] error in self?.logger.error("평면 충돌면 생성 실패: \(error.localizedDescription)") }
    )

    private(set) var recognizedArea: Float = 0
    var recognizedAreaPublisher: AnyPublisher<Float, Never> {
        recognizedAreaSubject.eraseToAnyPublisher()
    }

    func addPlane(for anchor: ARPlaneAnchor) {
        guard isRunning, let scene, planeEntities[anchor.identifier] == nil else { return }
        let entity = ModelEntity()
        entity.name = "Plane"
        entity.components.set(PhysicsBodyComponent(mode: .static))
#if targetEnvironment(simulator)
        let anchorEntity = AnchorEntity(world: anchor.transform)
#else
        let anchorEntity = AnchorEntity(.anchor(identifier: anchor.identifier))
#endif
        anchorEntity.addChild(entity)
        scene.addAnchor(anchorEntity)
        planeEntities[anchor.identifier] = entity
        updatePlane(for: anchor)
    }

    func updatePlane(for anchor: ARPlaneAnchor) {
        guard isRunning, planeEntities[anchor.identifier] != nil else { return }
        let geometry = PlaneCollisionGeometry(
            vertices: anchor.geometry.vertices.map { SIMD3<Float>($0) },
            indices: anchor.geometry.triangleIndices.map { UInt32($0) },
            isHorizontal: anchor.alignment == .horizontal
        )
        if geometries[anchor.identifier] != geometry {
            geometries[anchor.identifier] = geometry
            planeAreas[anchor.identifier] = geometry.area
            publishAreaSum()
        }
        updates.enqueue(geometry, for: anchor.identifier)
    }

    func removePlane(for anchor: ARPlaneAnchor) {
        updates.remove(anchor.identifier)
        planeEntities.removeValue(forKey: anchor.identifier)?.parent?.removeFromParent()
        geometries[anchor.identifier] = nil
        planeAreas[anchor.identifier] = nil
        publishAreaSum()
    }

    func disablePlaneVisualization() {
        showsVisualization = false
        for entity in planeEntities.values { entity.model = nil }
    }

    /// 색상만 바뀔 때 메시·충돌면을 다시 만들지 않는다. 숨긴 평면도 다시 표시하지 않는다.
    func setVisualizationColor(_ color: UIColor) {
        guard visualizationColor != color else { return }
        visualizationColor = color
        for entity in planeEntities.values where entity.model != nil {
            entity.model?.materials = [visualizationMaterial()]
        }
    }

    func pause() {
        isRunning = false
        updates.stop()
    }

    func resume() {
        isRunning = true
        for (id, geometry) in geometries { updates.enqueue(geometry, for: id) }
    }

    func reset() {
        pause()
        updates.reset()
        planeEntities.values.forEach { $0.parent?.removeFromParent() }
        planeEntities = [:]
        geometries = [:]
        planeAreas = [:]
        showsVisualization = true
        publishAreaSum()
    }

    private func apply(_ geometry: PlaneCollisionGeometry, for id: UUID) async throws {
        guard isRunning, let entity = planeEntities[id] else { throw CancellationError() }
        let interval = signposter.beginInterval("PlaneCollision")
        defer { signposter.endInterval("PlaneCollision", interval) }
        var descriptor = MeshDescriptor()
        descriptor.positions = MeshBuffers.Positions(geometry.vertices)
        descriptor.primitives = .triangles(geometry.indices)
        let mesh = try MeshResource.generate(from: [descriptor])
        let shape = try await ShapeResource.generateStaticMesh(from: mesh)
        try Task.checkCancellation()
        guard isRunning, planeEntities[id] === entity else { throw CancellationError() }
        entity.components.set(CollisionComponent(shapes: [shape]))
        if showsVisualization {
            entity.model = ModelComponent(mesh: mesh, materials: [visualizationMaterial()])
        }
    }

    private func visualizationMaterial() -> UnlitMaterial {
        var material = UnlitMaterial()
        material.color = .init(tint: visualizationColor)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.6))
        return material
    }

    private func publishAreaSum() {
        let rounded = (planeAreas.values.reduce(0, +) * 10).rounded() / 10
        guard recognizedArea != rounded else { return }
        recognizedArea = rounded
        recognizedAreaSubject.send(rounded)
    }
}
