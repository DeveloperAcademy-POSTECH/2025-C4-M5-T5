//
//  HostNameInputView.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/17/25.
//

import SwiftUI

struct HostNameInputView: View {
    @State private var host_nickname: String = ""
    @EnvironmentObject private var navigationManager: NavigationManager

    var body: some View {
        ZStack {
            Color("White1")
                .ignoresSafeArea()
            NameInputFormView(
                title: "닉네임을 입력해주세요",
                nickname: $host_nickname,
                onSubmit: {
                    let newRoom = Room(
                        name: host_nickname,
                        currentPlayers: 1,
                        maxPlayers: 4
                    )
                    navigationManager.path.append(.waitingRoom(newRoom))
                },
                autoFocus: true
            )
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    navigationManager.pop()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.brown1)
                }
            }
        }
    }
}

#Preview {
    HostNameInputView()
}
