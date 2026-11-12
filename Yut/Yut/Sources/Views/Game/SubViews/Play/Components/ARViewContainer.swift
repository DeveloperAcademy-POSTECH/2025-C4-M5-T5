import RealityKit
import SwiftUI

/// 화면 모델이 소유한 AR 서비스 하나를 UIKit에 연결한다.
struct ARViewContainer: UIViewRepresentable {
    let scene: any GameSceneManaging
    func makeCoordinator() -> any GameSceneManaging { scene }
    func makeUIView(context: Context) -> ARView { scene.makeView() }
    func updateUIView(_ uiView: ARView, context: Context) {}
    static func dismantleUIView(_ uiView: ARView, coordinator: any GameSceneManaging) { coordinator.pause() }
}
