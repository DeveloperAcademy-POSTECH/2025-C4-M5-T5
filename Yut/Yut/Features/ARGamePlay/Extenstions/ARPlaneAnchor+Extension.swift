//
//  ARPlaneAnchor+Extension.swift
//  Yut
//
//  Created by yunsly on 7/17/25.
//

import ARKit
import simd


extension ARPlaneAnchor {
    
    // 삼각형 메시 기반으로 실제 평면 면적 계산
    var meshArea: Float {
        let vertices = geometry.vertices.map { SIMD3<Float>($0) }
        let indices = geometry.triangleIndices
        
        var totalArea: Float = 0.0
        
        for i in stride(from: 0, to: indices.count, by: 3) {
            let i0 = Int(indices[i])
            let i1 = Int(indices[i+1])
            let i2 = Int(indices[i+2])
            
            let a = vertices[i0]
            let b = vertices[i1]
            let c = vertices[i2]
            
            // 신발끈 공식으로 삼각형 면적 계산
            let cross = simd_cross(b - a, c - a)
            
            totalArea += 0.5 * simd_length(cross)
        }
        
        return totalArea
    }
}
