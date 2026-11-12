import SwiftUI
import UIKit
import RealityKit

extension UIColor {
    static func fromAsset(named name: String, alpha: CGFloat = 1.0) -> UIColor {
        if let color = UIColor(named: name) {
            return color.withAlphaComponent(alpha)
        } else {
            print("⚠️ Color asset '\(name)' not found. Using fallback color.")
            return UIColor.brown.withAlphaComponent(alpha)
        }
    }
}
