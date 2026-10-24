import SwiftUI

/// `#RRGGBB` maths for the Card style: the contrast rule of the web (`packages/shared/src/rules/colors.ts`), so both draw the same thing.
enum PagerColors {
    /// Waffi teal.
    static let fallback = "#2F766B"

    static func isValid(_ hex: String) -> Bool {
        hex.range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil
    }

    private static func channels(_ hex: String) -> (r: Double, g: Double, b: Double) {
        let value = UInt32((isValid(hex) ? hex : fallback).dropFirst(), radix: 16) ?? 0
        return (Double((value >> 16) & 0xFF) / 255, Double((value >> 8) & 0xFF) / 255, Double(value & 0xFF) / 255)
    }

    static func color(_ hex: String) -> Color {
        let c = channels(hex)
        return Color(red: c.r, green: c.g, blue: c.b)
    }

    private static func luminance(_ hex: String) -> Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        let c = channels(hex)
        return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b)
    }

    /// WCAG contrast ratio of two colours.
    static func contrast(_ first: String, _ second: String) -> Double {
        let a = luminance(first), b = luminance(second)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// White text on `hex` where it reaches 4.5:1, black everywhere else.
    static func onColor(_ hex: String) -> Color {
        contrast("#FFFFFF", hex) >= 4.5 ? .white : .black
    }

    /// `hex` moved `amount` (0...1) of the way to `other`.
    static func mix(_ hex: String, with other: String, _ amount: Double) -> String {
        let a = channels(hex), b = channels(other)
        func part(_ x: Double, _ y: Double) -> Int { Int(((x + (y - x) * amount) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", part(a.r, b.r), part(a.g, b.g), part(a.b, b.b))
    }
}
