//
//  NavigationManager.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/21/25.
//

import SwiftUI

final class NavigationManager: ObservableObject {
    @Published var path: [Route] = []

    /// 화면 이동
    func push(_ route: Route) {
        path.append(route)
    }

    /// 뒤로가기
    func pop() {
        _ = path.popLast()
    }

    /// 루트로 이동
    func popToRoot() {
        path.removeAll()
    }
}
