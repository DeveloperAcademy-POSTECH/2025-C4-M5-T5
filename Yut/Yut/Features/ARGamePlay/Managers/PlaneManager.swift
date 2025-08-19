//
//  PlaneManager.swift
//  Yut
//
//  Created by yunsly on 7/27/25.
//

import ARKit
import Combine
import RealityKit

final class PlaneManager {
    weak var coordinator: ARCoordinator?
    private var planeEntities: [UUID: ModelEntity] = [:]

    init(coordinator: ARCoordinator) {
        self.coordinator = coordinator
    }

    func addPlane(for anchor: ARPlaneAnchor) {
        guard let arView = coordinator?.arView else { return }

        var planeMesh: MeshResource
        do {
            let vertices = anchor.geometry.vertices.map { SIMD3<Float>($0) }
            let faceIndices = anchor.geometry.triangleIndices

            var descriptor = MeshDescriptor()
            descriptor.positions = MeshBuffers.Positions(vertices)
            descriptor.primitives = .triangles(faceIndices.map { UInt32($0) })
            planeMesh = try .generate(from: [descriptor])
        } catch {
            print("평면 앵커용 메시 생성 오류: \(error)")
            return
        }
        
        // Material 생성 및 색상 적용
        let uiColor = UIColor(named: "white1")?.withAlphaComponent(0.6) ?? .white
        var material = UnlitMaterial()
        material.baseColor = MaterialColorParameter.color(uiColor)
        
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])
        planeEntity.name = "Plane"
        
        planeEntity.components.set(PhysicsBodyComponent(mode: .static))
        
#if targetEnvironment(simulator)
        let anchorEntity = AnchorEntity(world: anchor.transform) // 시뮬레이터에서는 월드 기준 anchor
#else
        let anchorEntity = AnchorEntity(anchor: anchor) // 실제 디바이스에서는 ARAnchor 기반
#endif
        anchorEntity.addChild(planeEntity)
        
        arView.scene.addAnchor(anchorEntity)
        self.planeEntities[anchor.identifier] = planeEntity
    }
    
    func updatePlane(for anchor: ARPlaneAnchor) {
        guard let planeEntity = self.planeEntities[anchor.identifier] else { return }
        
        do {
            let vertices = anchor.geometry.vertices.map { SIMD3<Float>($0) }
            let faceIndices = anchor.geometry.triangleIndices
            
            var descriptor = MeshDescriptor()
            descriptor.positions = MeshBuffers.Positions(vertices)
            descriptor.primitives = .triangles(faceIndices.map { UInt32($0) })
            
            let updatedMesh = try MeshResource.generate(from: [descriptor])
            planeEntity.model?.mesh = updatedMesh
            
            Task { @MainActor in
                do {
                    let shape = try await ShapeResource.generateStaticMesh(from: updatedMesh)
                    planeEntity.components.set(CollisionComponent(shapes: [shape]))
                } catch {
                    print("❌ 정밀 충돌면 생성 실패: \(error)")
                }
            }
        } catch {
            print("❌ 평면 메시 업데이트 실패: \(error)")
        }
    }
    
    // 평면 제거 시 호출
    func removePlane(for anchor: ARPlaneAnchor) {
        guard let entity = planeEntities[anchor.identifier] else { return }
        
        entity.removeFromParent()
        planeEntities.removeValue(forKey: anchor.identifier)
        
        print("🗑️ 평면 제거됨: \(anchor.identifier)")
    }
    
    func disablePlaneVisualization() {
        for (_, entity) in planeEntities {
            entity.model?.materials = [SimpleMaterial(color: .clear, isMetallic: false)]
        }
    }
}
