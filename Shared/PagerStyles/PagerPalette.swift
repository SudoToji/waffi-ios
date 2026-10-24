import SwiftUI

/// The colours of one Card style: the card, the text on it, and the brand colour where it can be used.
///
/// The brand colour is used as chosen for fills (logo tile, filled ring, stub) with black or white on top. As text, ring dots and
/// track lines it is used only where it reaches 3:1 on the card (what the web preview does); otherwise the plain text colour is.
struct PagerPalette {
    /// The card colour for `activityBackgroundTint` (a see-through dim when transparent); nil only for the Island.
    let background: Color?
    let ink: Color
    let secondary: Color
    let hairline: Color
    let brand: Color
    let brandHex: String
    /// Black or white, whichever reads on a brand fill.
    let onBrand: Color
    /// The brand colour where it reads on the card, the text colour where it would vanish.
    let accent: Color

    /// - Parameter island: the Dynamic Island, which is always black whatever the style.
    init(_ style: PagerStyle, island: Bool = false) {
        let (light, surface) = Self.surface(of: style, island: island)
        // Transparent: a light dim over the wallpaper. Nil would give iOS's default card, which is near-opaque black.
        background = island ? nil : style.background == .transparent ? Color.black.opacity(0.35) : PagerColors.color(surface)
        ink = light ? PagerColors.color("#1B1B1A") : .white
        secondary = light ? PagerColors.color("#5C5C57") : Color.white.opacity(0.7)
        hairline = light ? PagerColors.color("#DCDCD7") : Color.white.opacity(0.15)
        brandHex = style.color
        brand = PagerColors.color(style.color)
        onBrand = PagerColors.onColor(style.color)
        accent = PagerColors.contrast(style.color, surface) >= 3 ? brand : ink
    }

    /// The card colour the text and the brand colour sit on, and whether it is light.
    private static func surface(of style: PagerStyle, island: Bool) -> (light: Bool, hex: String) {
        if island { return (false, "#000000") }
        // Light text on the lock screen's dark glass.
        if style.background == .transparent { return (false, "#1C1C1E") }
        switch style.layout {
        case .ring, .arabic: return (true, "#F3F3F0")
        case .stub: return (false, "#1C1C1E")
        case .track: return (false, style.wording == .car ? "#0F2147" : "#2B2724")
        // The card is the brand colour itself: dark text on a light brand, white on a dark one.
        case .segments: return (PagerColors.contrast("#FFFFFF", style.color) < 4.5, style.color)
        case .route: return (true, "#FFFFFF")
        }
    }

    /// Status text and track: the accent, gray once ended.
    func status(_ state: PagerState) -> Color {
        state == .ended ? secondary : accent
    }

    /// The ring: dots in the accent while waiting, a solid brand disc when ready.
    func ring(_ state: PagerState) -> Color {
        switch state {
        case .waiting: accent
        case .ready: brand
        case .ended: secondary
        }
    }
}
