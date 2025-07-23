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
import Combine

class ARContentManager {
    
    // MARK: - Properties
    weak var coordinator: ARCoordinator?
    
    // 사용자가 조작할 윷판 앵커와 시각화된 평면들을 관리
    var yutBoardAnchor: AnchorEntity?
    var planeEntities: [UUID: ModelEntity] = [:]
    
    // 윷 관련 변수
    var yutEntities: [Entity] = []
    var yutHoldingAnchor: AnchorEntity?
    
    // 하이라이트된 엔티티들의 기존값 저장
    var originalMaterials: [String: RealityFoundation.Material] = [:]
    
    // 생성된 말들을 관리하기 위한 배열
    var pieceEntities: [Entity] = []
    
    private var animationSubscriptions = Set<AnyCancellable>()
    
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
            boardEntity.generateCollisionShapes(recursive: true)
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
    
    // 말을 지정된 타일 위에 배치
    // TODO: 어떤 말을 배치할 것인지 인자로 넘기자.
    func placeNewPiece(on tileName: String) {
        guard let boardEntity = yutBoardAnchor?.children.first,
              let tileEntity = boardEntity.findEntity(named: tileName) else {
            print("오류: \(tileName) 타일을 찾을 수 없습니다.")
            return
        }
        
        do {
            let pieceEntity = try ModelEntity.load(named: "Piece1_yellow.usdz")
            pieceEntity.generateCollisionShapes(recursive: true)
            pieceEntity.scale = [0.3, 8.0, 0.3]
            
            // 로드한 '말' 엔티티에 고유한 이름을 부여
            pieceEntity.name = "yut_piece_\(pieceEntities.count)"
            
            pieceEntity.position = [0, 0.2, 0]
            tileEntity.addChild(pieceEntity)
            pieceEntities.append(pieceEntity)
            print("\(tileName)에 새로운 말을 배치했습니다.")
            
        } catch {
            print("오류: 말 모델(Piece.usdz) 로딩에 실패했습니다: \(error)")
        }
    }
    
    func movePiece(piece: Entity, to tileName: String) {
            guard let boardEntity = yutBoardAnchor?.children.first,
                  let destinationTile = boardEntity.findEntity(named: tileName) else {
                print("오류: 목적지 \(tileName) 타일을 찾을 수 없습니다.")
                return
            }


            var destinationPosition = destinationTile.position(relativeTo: nil)
            destinationPosition.y += 0.02

            var destinationTransform = Transform(matrix: piece.transformMatrix(relativeTo: nil))
            destinationTransform.translation = destinationPosition

            piece.move(
                to: destinationTransform,
                relativeTo: nil,
                duration: 0.5,
                timingFunction: .easeInOut
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("\(piece.name)의 이동 애니메이션 완료. 부모를 \(tileName)으로 변경합니다.")
            
                piece.setParent(destinationTile)
                piece.setPosition([0, 0.02, 0], relativeTo: destinationTile)
            }
            
            print("\(piece.name) 말을 \(tileName)으로 이동 시작.")
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
    
    // MARK: - Highlight Management
    func highlightPositions(names: [String]) {
        
        guard let boardEntity = yutBoardAnchor?.children.first else {
            print("오류: 윷판 엔티티를 찾을 수 없습니다.")
            return
        }
        
        clearHighlights()
        
        for name in names {
            if let tileEntity = boardEntity.findEntity(named: name) as? ModelEntity {
                // 현재 머티리얼 저장
                if let material = tileEntity.model?.materials.first {
                    originalMaterials[name] = material
                }
                
                var emissiveMaterial = UnlitMaterial()
                emissiveMaterial.color = .init(tint: .yellow.withAlphaComponent(0.8))
                
                
                // 모델의 머티리얼을 발광 머티리얼로 교체
                if var model = tileEntity.model {
                    model.materials = [emissiveMaterial]
                    tileEntity.model = model
                    
                    print("\(name) 위치를 하이라이트했습니다.")
                } else {
                    print("오류: \(name) 위치에는 Model 컴포넌트가 없습니다.")
                }
            } else {
                print("오류: \(name) 이라는 이름의 타일을 찾지 못했습니다.")
            }
        }
    }
    
    func clearHighlights() {
        guard let boardEntity = yutBoardAnchor?.children.first else { return }
        
        for (name, originalMaterial) in originalMaterials {
            if let tileEntity = boardEntity.findEntity(named: name) as? ModelEntity,
               var model = tileEntity.model {
                model.materials = [originalMaterial]
                tileEntity.model = model
            }
        }
        originalMaterials.removeAll()
    }
    
}
