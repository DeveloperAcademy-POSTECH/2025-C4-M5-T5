//
//  HomeView.swift
//  Yut
//
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    
    var body: some View {
        DecoratedBackground{
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
                    ) { navigationManager.push(.hostNameInput) }
                    
                    UIViewButton(
                        title: "방 참여하기",
                        isEnabled: true
                    ) { navigationManager.push(.guestNameInput) }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    HomeView()
}
