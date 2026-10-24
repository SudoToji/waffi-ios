import SwiftUI

/// The Waffi dashboard palette (`apps/web/src/shared/styles/calm.css`), light and dark. Secondary text, borders and the segmented
/// track have no dark value there; the dark ones here are picked to sit on the dark cards.
enum Theme {
    static let accent = Color(light: 0x2E5A43, dark: 0x86C49F)
    static let accentPressed = Color(light: 0x1F3F2E, dark: 0x6BA886)
    static let accentTint = Color(light: 0xE6EFE9, dark: 0x1F3328)
    /// Text and icons on `accent`.
    static let onAccent = Color(light: 0xFFFFFF, dark: 0x1B201D)
    static let background = Color(light: 0xF2F3F0, dark: 0x1B201D)
    static let card = Color(light: 0xFFFFFF, dark: 0x252B27)
    static let text = Color(light: 0x1F2622, dark: 0xC3C9C5)
    static let secondaryText = Color(light: 0x5A635D, dark: 0x9AA39D)
    static let border = Color(light: 0xD5D9D3, dark: 0x3A423D)
    static let track = Color(light: 0xE4E6E1, dark: 0x303732)
    static let warning = Color(light: 0xB45309, dark: 0xF59E0B)
    /// The full-screen QR is the brand green in every appearance, with white on it.
    static let brand = Color(hex: 0x2E5A43)
    static let onBrandSecondary = Color(hex: 0xCFE3D6)
}

private extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}
