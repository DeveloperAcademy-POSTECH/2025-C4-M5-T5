//
//  HomeView.swift
//  YUT
//
//

import SwiftUI

struct HomeView: View {
    @ObservedObject private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) { self.viewModel = viewModel }
    
    var body: some View {
        DecoratedBackground{
            VStack {
                Spacer()
                Text("윷")
                    .foregroundStyle(ThemeColors.textPrimary)
                    .font(.hancom(.hoonmin, size: 236))
                    .padding(.top, 32)
                Spacer()
                
                VStack(spacing: 12) {
                    ActionButton(title: "한 기기로 플레이", action: viewModel.playLocally)
                    ActionButton(
                        title: "방 만들기",
                        variant: .secondary
                    ) { viewModel.createRoom() }
                    
                    ActionButton(
                        title: "방 참여하기",
                        variant: .secondary
                    ) { viewModel.joinRoom() }
                }
            }
            .overlay(alignment: .topTrailing) {
                IconButton(systemName: "gearshape", accessibilityLabel: "설정", action: viewModel.showSettings)
            }
            .padding(.horizontal, 20)
        }
    }
}

