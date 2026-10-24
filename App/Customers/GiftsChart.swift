import Charts
import SwiftUI

/// "Gifts per month": two bars per Cairo month, earned then redeemed, over 3, 6 or 12 months.
struct GiftsChart: View {
    let months: [GiftMonth]
    @Binding var period: Int

    private struct Point: Identifiable {
        let month: Date
        let kind: String
        let count: Int
        var id: String { "\(month.timeIntervalSince1970)-\(kind)" }
    }

    private let earned = String(localized: "Gifts earned")
    private let redeemed = String(localized: "Gifts redeemed")

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Gifts per month")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.text)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                Picker("Months shown", selection: $period) {
                    ForEach([3, 6, 12], id: \.self) { Text($0.formatted()).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 160)
            }
            Chart(points) { point in
                BarMark(x: .value("Month", point.month, unit: .month), y: .value("Gifts", point.count))
                    .foregroundStyle(by: .value("Kind", point.kind))
                    .position(by: .value("Kind", point.kind))
            }
            .chartForegroundStyleScale(domain: [earned, redeemed], range: [Theme.accent, Theme.ember])
            .chartLegend(position: .bottom)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.narrow))
                }
            }
            .frame(height: 180)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Gifts per month"))
            .accessibilityValue(Text(verbatim: summary))
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private var points: [Point] {
        months.flatMap { row -> [Point] in
            guard let date = Self.date(row.month) else { return [] }
            return [Point(month: date, kind: earned, count: row.earned), Point(month: date, kind: redeemed, count: row.redeemed)]
        }
    }

    /// Every month in words, for VoiceOver: "March 2026: 2 earned, 1 redeemed".
    private var summary: String {
        months.compactMap { row -> String? in
            guard let date = Self.date(row.month) else { return nil }
            let name = date.formatted(.dateTime.month(.wide).year())
            return String(localized: "\(name): \(row.earned) earned, \(row.redeemed) redeemed")
        }
        .joined(separator: ". ")
    }

    /// `YYYY-MM` as the first of that month on the phone's calendar.
    private static func date(_ month: String) -> Date? {
        let parts = month.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: 1))
    }
}
