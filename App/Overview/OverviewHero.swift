import SwiftUI

/// The green stat card: this week's visits as the hero number with the week's bars, then Customers and Rewards redeemed.
struct OverviewHero: View {
    let analytics: BusinessAnalytics
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 56
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(alignment: .bottom))
            layout {
                visits
                if !typeSize.isAccessibilitySize { Spacer(minLength: 12) }
                bars
            }
            Rectangle().fill(.white.opacity(0.2)).frame(height: 1)
            HStack(alignment: .top, spacing: 0) {
                stat("Customers", total: analytics.customers.allTime, week: analytics.customers.last7Days)
                Rectangle().fill(.white.opacity(0.2)).frame(width: 1).padding(.horizontal, 16)
                stat("Rewards redeemed", total: analytics.giftsRedeemed.allTime, week: analytics.giftsRedeemed.last7Days)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(Theme.brand, in: RoundedRectangle(cornerRadius: 24))
    }

    private var visits: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Visits this week")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.onBrandSecondary)
            Text(analytics.visits.last7Days, format: .number)
                .font(.system(size: heroSize, weight: .heavy))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if let change = analytics.visitsChange { changePill(change) }
        }
        .accessibilityElement(children: .combine)
    }

    private func changePill(_ change: Double) -> some View {
        let percent = abs(change).formatted(.percent.precision(.fractionLength(0)))
        let direction = change > 0 ? "chevron.up" : change < 0 ? "chevron.down" : "minus"
        return HStack(spacing: 4) {
            Image(systemName: direction).font(.caption.weight(.heavy)).accessibilityHidden(true)
            Text("\(percent) vs last week").font(.footnote.weight(.bold)).monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.white.opacity(0.18), in: .capsule)
        .accessibilityLabel(change > 0 ? Text("Up \(percent) from last week") : change < 0 ? Text("Down \(percent) from last week") : Text("\(percent) vs last week"))
    }

    /// Seven bars, the oldest first and today in white. Time runs left to right in every language.
    private var bars: some View {
        let values = analytics.weekBars
        let top = max(values.max() ?? 0, 1)
        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                RoundedRectangle(cornerRadius: 3)
                    .fill(.white.opacity(index == values.count - 1 ? 1 : 0.35))
                    .frame(width: 10, height: max(6, 64 * CGFloat(value) / CGFloat(top)))
            }
        }
        .frame(height: 64, alignment: .bottom)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }

    private func stat(_ title: LocalizedStringKey, total: Int, week: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.onBrandSecondary)
            Text(total, format: .number).font(.title.weight(.heavy)).monospacedDigit()
            Text("+\(week, format: .number) this week").font(.footnote.weight(.semibold)).foregroundStyle(Theme.onBrandSecondary).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
