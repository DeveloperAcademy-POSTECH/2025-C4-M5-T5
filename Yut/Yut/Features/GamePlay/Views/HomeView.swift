//
//  HomeView.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/17/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Color("White1")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Image("top1")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, alignment: .top)
                    .ignoresSafeArea(edges: .top)

                Spacer()

                Image("bottom1")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(edges: .bottom)
            }
            
            
            VStack {
                Spacer()

                Text("윷")
                    .foregroundColor(.brown1)
                    .font(.hancom(.hoonmin, size: 236))
                
                Spacer()
                
                VStack(spacing: 12) {
                    RoundedBrownButton(
                        title: "방 만들기",
                        isEnabled: true
                    ) {
                        print("방 만들기 클릭")
                        // 방 만들기 액션
                    }
                    
                    RoundedBrownButton(
                        title: "방 참여하기",
                        isEnabled: true
                    ) {
                        print("방 참여하기 클릭")
                        // 방 참여하기 액션
                    }
                }
            }
            .padding(.horizontal, 16)
            
        }
    }
}

#Preview {
    HomeView()
}
