import Foundation

/// The eligible purchase amount a Staff Member types, in piastres (`purchaseMinorUnits` in waffi `packages/shared`).
enum PurchaseAmount {
    /// Most stamps one Earn may add to a stamps Card (`MAX_STAMPS_PER_EARN`).
    static let maxStamps = 20

    /// Up to seven digits and two decimals, above zero and at most EGP 1,000,000; nil otherwise. Arabic digits and the Arabic decimal mark are read.
    static func minorUnits(_ text: String) -> Int? {
        var value = ""
        for scalar in text.trimmingCharacters(in: .whitespaces).unicodeScalars {
            switch scalar.value {
            case 0x0660...0x0669: value.unicodeScalars.append(UnicodeScalar(scalar.value - 0x0660 + 0x30)!)
            case 0x06F0...0x06F9: value.unicodeScalars.append(UnicodeScalar(scalar.value - 0x06F0 + 0x30)!)
            case 0x066B: value.append(".")
            default: value.unicodeScalars.append(scalar)
            }
        }
        guard value.range(of: "^[0-9]{1,7}(\\.[0-9]{1,2})?$", options: .regularExpression) != nil else { return nil }
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        let whole = Int(parts[0]) ?? 0
        let fraction = parts.count > 1 ? Int(String(parts[1]).padding(toLength: 2, withPad: "0", startingAt: 0)) ?? 0 : 0
        let minor = whole * 100 + fraction
        return minor > 0 && minor <= 100_000_000 ? minor : nil
    }
}
