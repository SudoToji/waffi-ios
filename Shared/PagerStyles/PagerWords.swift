import Foundation

/// What a card says, in both languages at once (the Live Activity is not localized per phone language). Mirrors the web's
/// `pagerTicket.wording`, the Ready push alerts and the mockups; `order` keeps the original texts.
struct PagerWords {
    let en: String
    let ar: String
    /// A second Arabic line, read only by the Arabic-first layout.
    var detailAR: String?
}

extension Locale {
    /// Layouts E and F follow the phone language; A to D are bilingual by design.
    var isArabic: Bool { language.languageCode?.identifier == "ar" }
}

extension PagerWords {
    func text(arabic: Bool) -> String { arabic ? ar : en }
}

extension PagerWording {
    func words(for state: PagerState) -> PagerWords {
        switch (self, state) {
        case (_, .ended): PagerWords(en: "Ended", ar: "انتهى")
        case (.order, .waiting): PagerWords(en: "Preparing", ar: "قيد التحضير", detailAR: "هنبلغك أول ما يجهز")
        case (.order, .ready): PagerWords(en: "Ready, collect your order", ar: "طلبك جاهز", detailAR: "تفضل استلمه من الكاونتر")
        case (.coffee, .waiting): PagerWords(en: "Brewing your coffee", ar: "قهوتك بتتحضر")
        case (.coffee, .ready): PagerWords(en: "Your coffee is ready, enjoy", ar: "قهوتك جاهزة")
        case (.car, .waiting): PagerWords(en: "Washing your car", ar: "بنغسل عربيتك")
        case (.car, .ready): PagerWords(en: "Your car is ready", ar: "عربيتك جاهزة")
        case (.turn, .waiting): PagerWords(en: "You're in the queue", ar: "انت في الدور، هنبلغك")
        case (.turn, .ready): PagerWords(en: "It's your turn, come in", ar: "جه دورك، اتفضل")
        }
    }

    /// The three steps of the progress track: received, the work, ready.
    var trackSteps: [PagerWords] {
        switch self {
        case .order: [PagerWords(en: "Received", ar: "تم الاستلام"), PagerWords(en: "Preparing", ar: "قيد التحضير"), PagerWords(en: "Ready", ar: "جاهز")]
        case .coffee: [PagerWords(en: "Received", ar: "تم الاستلام"), PagerWords(en: "Brewing", ar: "بتتحضر"), PagerWords(en: "Ready", ar: "جاهزة")]
        case .car: [PagerWords(en: "Queued", ar: "في الانتظار"), PagerWords(en: "Washing", ar: "بنغسلها"), PagerWords(en: "Ready", ar: "جاهزة")]
        case .turn: [PagerWords(en: "Joined", ar: "انضممت"), PagerWords(en: "In queue", ar: "في الدور"), PagerWords(en: "Your turn", ar: "دورك")]
        }
    }

    /// The small caption over the number on a ticket stub.
    var numberLabel: String {
        self == .turn ? "TURN" : "ORDER"
    }
}
