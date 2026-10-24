import SwiftUI

/// A warning only: the Staff Member may still continue. Counts are today's (Cairo) and exclude undone Operations.
struct TodayWarning: View {
    let today: CardToday

    var body: some View {
        if today.stamps >= CardToday.stampsWarning || today.redemptions >= CardToday.redemptionsWarning {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill").accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    if today.stamps >= CardToday.stampsWarning { Text("Already got \(today.stamps) stamps today") }
                    if today.redemptions >= CardToday.redemptionsWarning { Text("Already redeemed \(today.redemptions) Rewards today") }
                }
                .font(.subheadline.weight(.semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.warning)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            .accessibilityElement(children: .combine)
        }
    }
}
