import SwiftUI

/// The Waiting and Ready switch with the number of tickets in each.
struct PagerTabs: View {
    /// `waiting` or `ready`.
    @Binding var selection: String
    let waiting: Int
    let ready: Int

    var body: some View {
        HStack(spacing: 6) {
            tab("waiting") { Text("Waiting · \(waiting)") }
            tab("ready") { Text("Ready · \(ready)") }
        }
        .padding(4)
        .background(Theme.track, in: RoundedRectangle(cornerRadius: 12))
    }

    private func tab(_ state: String, @ViewBuilder label: () -> some View) -> some View {
        let selected = selection == state
        return Button { selection = state } label: {
            label()
                .font(.subheadline.weight(selected ? .bold : .semibold))
                .foregroundStyle(selected ? Theme.text : Theme.secondaryText)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(selected ? Theme.card : .clear, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
