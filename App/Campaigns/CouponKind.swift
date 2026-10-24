import SwiftUI

/// The coupon kinds of the website's editor: a writing aid only, the API stores just the text (`coupon-text.ts`).
enum CouponKind: String, CaseIterable, Identifiable {
    case freeItem = "free_item"
    case discountPercent = "discount_percent"
    case discountAmount = "discount_amount"
    case custom

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .freeItem: "Free item"
        case .discountPercent: "Percentage discount"
        case .discountAmount: "Fixed discount"
        case .custom: "Custom reward"
        }
    }

    /// The coupon text a kind and its detail write, in the language the message is written in. An empty or invalid detail gives "".
    func text(detail: String, locale: String) -> String {
        if self == .custom { return detail }
        let words = Self.digits(detail).split(whereSeparator: \.isWhitespace).joined(separator: " ")
        if self == .freeItem {
            guard let first = words.first else { return "" }
            // A proper name keeps its capitals ("Waffi Cup"); a plain first word is lower-cased after "Free".
            let rest = String(words.dropFirst())
            let proper = rest.contains(where: { $0.isASCII && $0.isUppercase })
            let item = proper ? words : first.lowercased() + rest
            return locale == "ar" ? words + " مجانًا" : "Free " + item
        }
        guard let value = Double(words), value.isFinite else { return "" }
        let inRange = self == .discountPercent ? (1...100).contains(value) : (value > 0 && value <= 1_000_000)
        guard inRange else { return "" }
        let number = value == value.rounded() ? String(Int(value)) : String(value)
        let amount = self == .discountPercent ? number + "%" : number + (locale == "ar" ? " جنيه" : " EGP")
        return locale == "ar" ? "خصم " + amount : amount + " off"
    }

    /// Arabic-Indic digits and the Arabic decimal separator typed on an Arabic keyboard, as Western ones.
    private static func digits(_ text: String) -> String {
        var out = ""
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x0660...0x0669: out.unicodeScalars.append(UnicodeScalar(scalar.value - 0x0660 + 0x30)!)
            case 0x06F0...0x06F9: out.unicodeScalars.append(UnicodeScalar(scalar.value - 0x06F0 + 0x30)!)
            case 0x066B, 0x066C, 0x002C: out.append(".")
            default: out.unicodeScalars.append(scalar)
            }
        }
        return out
    }
}
