import SwiftUI

/// The slots of a stamps Card: filled ones with a tick, the next one in the accent colour, the last one a gift.
struct StampGrid: View {
    let count: Int
    let filled: Int

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: count <= 8 ? 4 : count <= 10 ? 5 : 6)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<count, id: \.self) { index in
                slot(index)
            }
        }
        .accessibilityHidden(true)
    }

    private func slot(_ index: Int) -> some View {
        let isFilled = index < filled
        let isNext = index == filled
        let symbol: String? = isFilled ? "checkmark" : index == count - 1 ? "gift" : isNext ? "plus" : nil
        return ZStack {
            if isFilled {
                Circle().fill(Theme.accent)
            } else {
                Circle().strokeBorder(isNext ? Theme.ember : Theme.border, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
            }
            if let symbol {
                Image(systemName: symbol)
                    .font(.body.weight(.bold))
                    .foregroundStyle(isFilled ? Theme.onAccent : isNext ? Theme.ember : Theme.secondaryText)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 56)
    }
}
