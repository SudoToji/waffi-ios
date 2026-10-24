import SwiftUI

/// A day of the year with no year, stored as `MM-DD`: a month and a day. Picking a month starts at the first day;
/// a day the new month does not have becomes its last (February offers the 29th, as the website does).
struct MonthDayPicker: View {
    let title: LocalizedStringKey
    @Binding var value: String

    private var parts: (month: Int, day: Int) {
        guard MessageForm.monthDay(value), let month = Int(value.prefix(2)), let day = Int(value.suffix(2)) else { return (0, 0) }
        return (month, day)
    }

    private static func days(in month: Int) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: 2000, month: month)) ?? .now)?.count ?? 31
    }

    private static let months: [String] = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        return calendar.standaloneMonthSymbols
    }()

    private func pick(month: Int, day: Int) {
        guard month > 0 else {
            value = ""
            return
        }
        let clamped = min(max(day, 1), Self.days(in: month))
        value = String(format: "%02d-%02d", month, clamped)
    }

    var body: some View {
        let current = parts
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
            HStack {
                Picker(title, selection: Binding(get: { current.month }, set: { pick(month: $0, day: current.day) })) {
                    Text(verbatim: "—").tag(0)
                    ForEach(1...12, id: \.self) { month in
                        Text(verbatim: Self.months[month - 1]).tag(month)
                    }
                }
                Picker("Day", selection: Binding(get: { current.day }, set: { pick(month: current.month, day: $0) })) {
                    if current.month == 0 { Text(verbatim: "—").tag(0) }
                    ForEach(1...(current.month == 0 ? 1 : Self.days(in: current.month)), id: \.self) { day in
                        Text(day.formatted()).tag(day)
                    }
                }
                .disabled(current.month == 0)
            }
            .pickerStyle(.menu)
            .tint(Theme.accent)
        }
    }
}
