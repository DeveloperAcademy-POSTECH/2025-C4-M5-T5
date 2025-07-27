//
//  ARSessionLoadingView.swift
//  Yut
//
//  Created by soyeonsoo on 7/25/25.
//

import SwiftUI

struct ARSessionLoadingView: View {
    var body: some View {
        DecoratedBackground{
            InstructionView(text: "카메라가 켜지고 윷놀이가 시작됩니다!")
        }
    }
}

#Preview {
    ARSessionLoadingView()
}
