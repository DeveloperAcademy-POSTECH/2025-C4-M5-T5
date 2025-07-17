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
}
