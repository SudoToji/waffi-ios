import SwiftUI

/// The lock-screen banner: logo, Business name, the order number large, and the status line in the state's colour.
struct PagerLockScreenView: View {
    let attributes: PagerActivityAttributes
    let state: PagerState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                PagerLogoView(businessName: attributes.businessName, size: 48)
                VStack(alignment: .leading) {
                    Text(attributes.businessName).font(.headline).lineLimit(1)
                    if !attributes.branchName.isEmpty {
                        Text(attributes.branchName).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                Text(attributes.number)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Label(state.message, systemImage: state.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(state.color)
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}
