//
//  KeyboardObserver.swift
//  Yut
//
//  Created by Hwnag Seyeon on 7/17/25.
//

import Combine
import SwiftUI

class KeyboardObserver: ObservableObject {
    @Published var isKeyboardVisible: Bool = false
    
    init() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            self.isKeyboardVisible = true
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            self.isKeyboardVisible = false
        }
    }
}
