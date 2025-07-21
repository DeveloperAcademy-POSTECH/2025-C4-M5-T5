//
//  ARContentManager.swift
//  Yut
//
//  Created by yunsly on 7/21/25.
//
//  RealityKit 과 관련된 모든 시각적 처리를 담당

import SwiftUI
import RealityKit
import ARKit

class ARContentManager {
    
    // MARK: - Properties
    weak var coordinator: ARCoordinator?
    
    // 사용자가 조작할 윷판 앵커와 시각화된 평면들을 관리
    var yutBoardAnchor: AnchorEntity?
    var planeEntities: [UUID: ModelEntity] = [:]
    
    // 윷 관련 변수
    var yutEntities: [Entity] = []
    var yutHoldingAnchor: AnchorEntity?
    
    init(coordinator: ARCoordinator) {
        self.coordinator = coordinator
    }
    
    // MARK: - Board Management
    
    // 윷판 배치
    func placeYutBoard(on anchor: ARAnchor) {
        // 이미 생성되었다면 중복 생성 방지
        guard let arView = coordinator?.arView, let arState = coordinator?.arState else { return }
        if self.yutBoardAnchor != nil { return }

        do {
            let boardEntity = try ModelEntity.load(named: "Board.usdz")
            // boardEntity.scale = [2.0, 2.0, 2.0]
            
            let anchorEntity = AnchorEntity(anchor: anchor)
            anchorEntity.addChild(boardEntity)
            
            arView.scene.addAnchor(anchorEntity)
            self.yutBoardAnchor = anchorEntity
            
            // AppState 변경
            DispatchQueue.main.async {
                arState.currentState = .adjustingBoard
            }
            
            // 평면 시각화 비활성화
            disablePlaneVisualization()
        } catch {
            print("윷판 모델 로딩 실패: \(error)")
        }
    }
    
    // 윷판의 위치를 월드 공간에 고정
    func fixBoardPosition() {
        guard let arView = coordinator?.arView, let boardAnchor = yutBoardAnchor else { return }
        
        // 월드 기준 변환 행렬 추출
        let worldMatrix = boardAnchor.transformMatrix(relativeTo: nil)
        let fixedAnchor = AnchorEntity(world: worldMatrix)
        
        for child in boardAnchor.children {
            fixedAnchor.addChild(child.clone(recursive: true))
        }
        
        arView.scene.addAnchor(fixedAnchor)
        arView.scene.removeAnchor(boardAnchor)
        self.yutBoardAnchor = fixedAnchor
    }
    
    // MARK: - Yut Management
    
    func createYuts() {
        guard let arView = coordinator?.arView else { return }
        
        // 이전에 있던 윷 제거
        yutHoldingAnchor?.removeFromParent()
        yutEntities.removeAll()
        
        // 카메라에 고정되는 앵커 생성
        let holdingAnchor = AnchorEntity(.camera)
        arView.scene.addAnchor(holdingAnchor)
        self.yutHoldingAnchor = holdingAnchor
        
        let yutScale: Float = 0.05   // 윷 크기 조절
        for i in 0..<4 {
            do {
                let yutEntity = try ModelEntity.load(named: "Yut.usdz")
                let rotation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                yutEntity.orientation = rotation
                yutEntity.scale = [yutScale, yutScale, yutScale]
                
                let xOffset = (Float(i) - 1.5) * (yutScale * 1.2)
                yutEntity.position = [xOffset, -0.15, -0.4]
                holdingAnchor.addChild(yutEntity)
                yutEntities.append(yutEntity)
            } catch {
                print("윷 엔티티 오류!")
            }
        }
    }
    
    // MARK: - Plane Management
    
    func addPlane(for anchor: ARPlaneAnchor) {
        guard let arView = coordinator?.arView else { return }
        
        var planeMesh: MeshResource
        do {
            let vertices = anchor.geometry.vertices.map { SIMD3<Float>($0) }
            let faceIndices = anchor.geometry.triangleIndices
            
            var descriptor = MeshDescriptor()
            descriptor.positions = MeshBuffers.Positions(vertices)
            descriptor.primitives = .triangles(faceIndices.map { UInt32($0)})
            planeMesh = try .generate(from: [descriptor])
            
        } catch {
            print("평면 앵커용 메시 생성 오류: \(error)")
            return
        }
        
        let planeMaterial = SimpleMaterial(color: .green.withAlphaComponent(0.2), isMetallic: false)
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
        
        planeEntity.generateCollisionShapes(recursive: false)
        planeEntity.components.set(PhysicsBodyComponent(mode: .static))
        
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(planeEntity)
        
        arView.scene.addAnchor(anchorEntity)
        self.planeEntities[anchor.identifier] = planeEntity
    }
    
    func updatePlane(for anchor: ARPlaneAnchor) {
        guard let planeEntity = self.planeEntities[anchor.identifier] else { return }
        
        var updatedMesh: MeshResource
        do {
            let vertices = anchor.geometry.vertices.map { SIMD3<Float>($0) }
            let faceIndices = anchor.geometry.triangleIndices
            var descriptor = MeshDescriptor()
            descriptor.positions = MeshBuffers.Positions(vertices)
            descriptor.primitives = .triangles(faceIndices.map { UInt32($0) })
            updatedMesh = try .generate(from: [descriptor])
        } catch {
            print("평면 앵커용 메시 업데이트 오류: \(error)")
            return
        }
        
        planeEntity.model?.mesh = updatedMesh
        planeEntity.generateCollisionShapes(recursive: false)
    }
    
    func disablePlaneVisualization() {
        for (_, entity) in planeEntities {
            entity.model?.materials = [SimpleMaterial(color: .clear, isMetallic: false)]
        }
    }
    
}
