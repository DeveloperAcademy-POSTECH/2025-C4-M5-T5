//
//  ARView+Extension.swift
//  Yut
//
//  Created by yunsly on 7/17/25.
//

import RealityKit
import ARKit

extension ARView: ARCoachingOverlayViewDelegate {
    func addCoachig() {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = self.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.activatesAutomatically = true
        
        self.addSubview(coachingOverlay)
    }
    
    func resetARSession(for arView: ARView) {
        arView.session.pause()
        arView.scene.anchors.removeAll()

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }

        arView.environment.sceneUnderstanding.options.insert(.physics)

        arView.session.run(config, options: [.removeExistingAnchors])
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
}
