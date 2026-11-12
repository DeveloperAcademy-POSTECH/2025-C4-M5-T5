import Foundation
import SwiftUI
import Testing
import UIKit
@testable import Yut

@MainActor
struct DesignSystemContrastTests {
    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func pairedControlsAndTextKeepReadableContrast(style: UIUserInterfaceStyle) throws {
        let pairs: [(Color, Color)] = [
            (ThemeColors.primaryButtonText, ThemeColors.primaryButtonBackground),
            (ThemeColors.secondaryButtonText, ThemeColors.secondaryButtonBackground),
            (ThemeColors.disabledButtonText, ThemeColors.disabledButtonBackground),
            (ThemeColors.textPrimary, ThemeColors.canvas),
            (ThemeColors.textPrimary, ThemeColors.surface),
            (ThemeColors.textSecondary, ThemeColors.surface),
            (ThemeColors.placeholder, ThemeColors.canvas)
        ]
        for (foreground, background) in pairs {
            #expect(try contrast(foreground, on: background, style: style) >= 4.5)
        }
    }

    @Test
    func darkModeAccentAndForegroundSwitchTogether() throws {
        #expect(try luminance(rgba(ThemeColors.primaryButtonBackground, style: .dark)) > 0.8)
        #expect(try luminance(rgba(ThemeColors.primaryButtonText, style: .dark)) < 0.1)
        #expect(try luminance(rgba(ThemeColors.primaryButtonBackground, style: .light)) < 0.1)
        #expect(try luminance(rgba(ThemeColors.primaryButtonText, style: .light)) > 0.8)
    }

    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func fixedWinnerColorsUseFixedReadableText(style: UIUserInterfaceStyle) throws {
        for piece in PieceType.allCases {
            #expect(try contrast(piece.textColor, on: piece.backgroundColor, style: style) >= 4.5)
        }
    }

    private func rgba(_ color: Color, style: UIUserInterfaceStyle) throws -> SIMD4<Double> {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        try #require(resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        return SIMD4(Double(red), Double(green), Double(blue), Double(alpha))
    }

    private func luminance(_ rgba: SIMD4<Double>) -> Double {
        let channels = [rgba.x, rgba.y, rgba.z].map { $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
        return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722
    }

    private func contrast(_ foreground: Color, on background: Color, style: UIUserInterfaceStyle) throws -> Double {
        let fg = try rgba(foreground, style: style)
        let bg = try rgba(background, style: style)
        let composed = fg * fg.w + bg * (1 - fg.w)
        let light = max(luminance(composed), luminance(bg))
        let dark = min(luminance(composed), luminance(bg))
        return (light + 0.05) / (dark + 0.05)
    }
}
