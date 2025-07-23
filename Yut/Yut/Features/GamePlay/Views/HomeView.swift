//
//  HomeView.swift
//  Yut
//
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    
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
                    UIViewButton(
                        title: "방 만들기",
                        isEnabled: true
                    ) {
                        navigationManager.push(.hostNameInput)
                    }
                    
                    UIViewButton(
                        title: "방 참여하기",
                        isEnabled: true
                    ) {
                        navigationManager.push(.guestNameInput)
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
