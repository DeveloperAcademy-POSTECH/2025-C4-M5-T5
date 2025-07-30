//
//  YutGatheringView.swift
//  Yut
//
//  Created by soyeonsoo on 7/29/25.
//

import SwiftUI

struct YutGatheringSequenceView: View {
    @State private var frameIndex = 1
    let totalFrames = 30
    let frameRate = 1.0 / 30.0
    
    @Binding var isAnimationDone: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            Image(uiImage: loadFrame(index: frameIndex))
                .resizable()
                .scaledToFill()
                .frame(width: width + 60, height: height + 60)
                .position(x: width / 2, y: height / 2)
                .ignoresSafeArea()
                .onAppear {
                    startAnimation()
                }
        }
    }
    
    func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: frameRate, repeats: true) { timer in
            if frameIndex < totalFrames {
                frameIndex += 1
            } else {
                timer.invalidate()
                isAnimationDone = true
            }
        }
    }
    
    func loadFrame(index: Int) -> UIImage {
        let filename = String(format: "Yut.%04d", index)
        guard let path = Bundle.main.path(forResource: filename, ofType: "png"),
              let image = UIImage(contentsOfFile: path) else {
            print("프레임 \(index) 로드 실패: \(filename).png")
            return UIImage()
        }
        return image
    }
}
