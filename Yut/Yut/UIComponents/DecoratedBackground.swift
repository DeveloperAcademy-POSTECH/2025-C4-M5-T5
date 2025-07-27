//
//  DecoratedBackground.swift
//  Yut
//
//  Created by soyeonsoo on 7/21/25.
//

import SwiftUI

struct DecoratedBackground<Content: View>: View {
    let content: Content
    
    @State private var topOffset: CGSize = .zero
    @State private var bottomOffset: CGSize = .zero
    
    private let imageWidth: CGFloat = 1200
    private let imageHeight: CGFloat = 50
    private let topOffsetValue = CGSize(width: 276, height: -160)
    private let bottomOffsetValue = CGSize(width: -276, height: 160)
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack{
                    Color(.white1)
                    VStack {
                        animatedImage(name: "top_long", offset: topOffset)
                        
                        Spacer()
                        
                        animatedImage(name: "bottom_long", offset: bottomOffset)
                    }
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                    topOffset = topOffsetValue
                    bottomOffset = bottomOffsetValue
                }
            }
            .ignoresSafeArea()
    }
    
    private func animatedImage(name: String, offset: CGSize) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: imageWidth, height: imageHeight)
            .offset(offset)
    }
}

//#Preview {
//    DecoratedBackground { Text("Hello World!") }
//}
