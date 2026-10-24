import SwiftUI

/// A white rounded section of the composer.
struct ComposerCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
    }
}

/// A caption under a field: the length used, or a hint.
struct FieldCaption: View {
    let text: Text

    var body: some View {
        text.font(.footnote).foregroundStyle(Theme.secondaryText)
    }
}
