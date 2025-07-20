//
//  DecoratedBackground.swift
//  Yut
//
//  Created by soyeonsoo on 7/21/25.
//

import SwiftUI

struct DecoratedBackground<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color(.white1)
                .ignoresSafeArea()

            VStack {
                Image("top1")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                Image("bottom1")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .bottom)
            }
            .ignoresSafeArea()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
