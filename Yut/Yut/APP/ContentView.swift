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
                    //InstructionView(text: "주변 바닥을 충분히 색칠해 주세요.")
                    ProgressBar(text: "바닥을 충분히 색칠해 주세요.",
                                currentProgress: arState.recognizedArea,
                                minRequiredArea: arState.minRequiredArea)
                case .completedSearching:
                    ProgressBar(text: "바닥을 충분히 색칠해 주세요.",
                                currentProgress: arState.recognizedArea,
                                minRequiredArea: arState.minRequiredArea)
                case .placeBoard:
                    InstructionView(text: "탭해서 말판을 배치하세요.")
                case .adjustingBoard:
                    InstructionView(text: "핀치와 드래그로\n보드의 크기와 위치를 조정하세요.")
                case .boardConfirmed:
                    EmptyView()
                    //                case .readyToThrow:
                    //                    InstructionView(text: "핸드폰을 앞으로 흔들어\n윷을 던지세요!")
                case .selectingPieceToMove:
                    InstructionView(text: "움직일 말을 선택하세요.")
                case .selectingDestination:
                    InstructionView(text: "말을 옮길 곳을 선택하세요.")
                case .readyToThrow:
                    InstructionView(text: "버튼을 눌러 윷을 던져랏")
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
                    RoundedBrownButton(title: "윷놀이 시작!", isEnabled: true) {
                        arState.currentState = .readyToThrow
                    }
                case .readyToThrow:
                    RoundedBrownButton(title: "윷 던지기 활성화!", isEnabled: true) {
                        arState.actionStream.send(.startMonitoringMotion)
                    }
                case .selectingPieceToMove:
                    VStack {
                        InstructionView(text: "움직일 말을 탭하세요.")
                        HStack {
                            // "도, 개, 걸, 윷, 모" 버튼
                            ForEach(1 ..< 6) { i in
                                Button("\(i)칸") { arState.yutResult = i }
                                    .padding()
                                    .background(arState.yutResult == i ? Color.yellow : Color.brown)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        RoundedBrownButton(title: "새 말 놓기", isEnabled: true) {
                            arState.actionStream.send(.showDestinationsForNewPiece)
                        }
                    }
                case .selectingDestination:
                    EmptyView()
                    
                }
            }
        }
    }
    
}






