//
//  AddPlayerCard.swift
//  Yut
//
//  Created by soyeonsoo on 7/30/25.
//

import SwiftUI

struct AddPlayerCard: View {
    var action: () -> Void
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Color.white2)
                    .frame(width: 135, height: 135)
                
                Image(systemName: "plus")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.brown4)
            }
            .padding(.top, 36)
            .padding(.bottom, 25)
            .frame(
                width: UIScreen.main.bounds.width / 2 - 24,
                height: 289
            )
            .background(.white.opacity(0.35))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.35), lineWidth: 1)
            )
        }
    }
}
