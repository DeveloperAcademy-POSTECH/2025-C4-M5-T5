//
//  YutThrowButton.swift
//  Yut
//
//  Created by soyeonsoo on 7/30/25.
//

import SwiftUI

struct YutThrowButton: View {
    let sequence: Int
    let action: () -> Void
    
    var imageName: String {
            switch sequence {
            case 1: return "button1"
            case 2: return "button2"
            case 3: return "button3"
            case 4: return "button4"
            default: return "button1"
            }
        }

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 120)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
