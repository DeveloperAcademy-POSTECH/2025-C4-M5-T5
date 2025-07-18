import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

/// makeUIView(context:)는 SwiftUI의 UIViewRepresentable 프로토콜을 채택하면
/// SwiftUI 시스템이 자동으로 호출하면서 context도 자동으로 넘겨줌
// Context는 SwiftUI → UIKit 뷰 생성 시 전달되는 환경 정보
struct ARViewContainer: UIViewRepresentable {
    // ARView 띄우기
    let arView = ARView(frame: .zero)
    
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(arView: arView)
        coordinator.startMonitoringMotion() // ✅ 여기서 모션 감지 시작
        return coordinator
    }
    
    func makeUIView(context: Context) -> ARView {
        // ✅ 1. AR 세션 구성 생성
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal] // 수평면 인식
        
        // ✅ 2. 필요하면 Scene Reconstruction, 환경 텍스처 등 추가 설정도 가능
//         config.sceneReconstruction = .meshWithClassification
        
        // ✅ 3. 세션 시작 (트래킹 리셋 + 기존 앵커 제거)
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
//        // ✅ 4. 이후 필요한 앵커 추가 등 AR 구성 작업 진행
        let anchor = AnchorEntity(plane: .horizontal)
        arView.scene.addAnchor(anchor)
        
        // 1. 2미터 x 2미터 크기의 평면 메시(Plane Mesh)를 생성
        let planeMesh = MeshResource.generatePlane(width: 2.0, depth: 2.0)

        // 2. 투명한 평면을 만들기 위해 SimpleMaterial 생성 (색은 clear로, 금속성은 없음)
        let material = SimpleMaterial(color: .clear, isMetallic: false)

        // 3. 위에서 만든 메시와 머티리얼을 바탕으로 실제 모델 엔티티 생성 (RealityKit에서 보이거나 충돌 가능)
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])

        // 4. 충돌 감지를 위해 물리 엔진에서 사용할 충돌 모양 자동 생성
        planeEntity.generateCollisionShapes(recursive: true)

        // 5. 물리 엔진에서 고정된(static) 객체로 인식되도록 PhysicsBodyComponent 설정
        //    → 중력에 반응하지 않고, 다른 객체가 충돌하면 반응만 함
        planeEntity.physicsBody = PhysicsBodyComponent(mode: .static)
        
        arView.debugOptions.insert(.showPhysics)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
