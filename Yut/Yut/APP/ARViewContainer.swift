//
//  ARViewContainer.swift
//  Yut
//
//  Created by yunsly on 7/17/25.
//

import SwiftUI
import ARKit
import RealityKit

// UIKit 기반의 ARView를 SwiftUI에서 사용하기 위한 wrapper
struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var arState: ARState // ContentView로부터 arState를 받아서 관찰
    
    // MARK: - Coordinator 생성
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // swiftUI 뷰가 생성될 때 한번만 호출됨 -> ARView 초기화 & 설정
    func makeUIView(context: Context) -> some UIView {
        let arView = ARView(frame: .zero)
        
        // MARK: - Coordinator 설정
        context.coordinator.arView = arView
        context.coordinator.arState = arState
        arView.session.delegate = context.coordinator       // AR 이벤트 수신
        
        // MARK: - Gesture Recognizers 설정
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch))
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan))
        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation))
        
        arView.addGestureRecognizer(tapGesture)
        arView.addGestureRecognizer(pinchGesture)
        arView.addGestureRecognizer(panGesture)
        arView.addGestureRecognizer(rotationGesture)
        
        
        // MARK: - AR 환경설정 (Configuration)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        
        return arView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) { }
}
