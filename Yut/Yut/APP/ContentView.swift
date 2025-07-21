//
//  ContentView.swift
//  Yut
//
//  Created by yunsly on 7/17/25.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView : View {
    @StateObject var arState = ARState()
    
    var body: some View {
        ZStack {
            ARViewContainer(arState: arState)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                switch arState.currentState {
                case .searchingForSurface:
                    InstructionView(text: "주변 바닥을 충분히 색칠해 주세요.")
                case .completedSearching:
                    InstructionView(text: "주변 바닥을 충분히 색칠해 주세요.")    // 여기 다른 문구를 넣어야할까
                case .placeBoard:
                    InstructionView(text: "탭해서 말판을 배치하세요.")
                case .adjustingBoard:
                    InstructionView(text: "핀치와 드래그로\n보드의 크기와 위치를 조정하세요.")
                case .boardConfirmed:
                    EmptyView()
                case .readyToThrow:
                    InstructionView(text: "핸드폰을 앞으로 흔들어\n윷을 던지세요!")
                }
                Spacer()
                
                // 하단 버튼
                switch arState.currentState {
                case .searchingForSurface:
                    // 비활성화된 [다음] 버튼
                    RoundedBrownButton(title: "다음", isEnabled: false) { }
                case .completedSearching:
                    // 활성화된 [다음] 버튼
                    RoundedBrownButton(title: "다음", isEnabled: true) {
                        arState.currentState = .placeBoard
                        print("애애")
                    }
                case .placeBoard:
                    // 버튼 없음
                    EmptyView()
                case .adjustingBoard:
                    // [여기에 배치] 버튼
                    RoundedBrownButton(title: "여기에 배치", isEnabled: true) {
                        arState.actionStream.send(.fixBoardPosition)
                        arState.actionStream.send(.disablePlaneVisualization)
                        arState.currentState = .boardConfirmed
                    }
                case .boardConfirmed:
                    // [윷놀이 시작!] 버튼 -> 객체 생성
                    RoundedBrownButton(title: "윷놀이 시작!", isEnabled: true) {
                        arState.actionStream.send(.createYuts)
                        arState.currentState = .readyToThrow
                    }
                case .readyToThrow:
                    // 윷 던지는 버튼
                    EmptyView()
                    
                }
            }
        }
    }
    
}






