import Foundation

/// Pure display helpers. `nonisolated` so views, models and `SortDescriptor` key paths can
/// all use them (PLAN.md pitfall 13 and 25).
///
/// All user-facing text goes through `String(localized:)` (PLAN.md pitfall 22) and every
/// interpolated number is an `Int`, so no locale-dependent decimal formatting can creep in
/// (PLAN.md pitfall 26). The half-kilo fraction is written out by hand for the same reason.
nonisolated enum Formatting {

    /// Multiplication sign U+00D7, not the letter x.
    static let timesSign = "\u{00D7}"

    /// "BW" for bodyweight, "40 kg" for 80 half-kilos, "22.5 kg" for 45.
    /// Always a normal space before "kg"; decimals only when needed.
    static func weightString(halfKilos: Int?) -> String {
        guard let halfKilos else { return String(localized: "BW") }
        let whole = halfKilos / 2
        if halfKilos % 2 == 0 {
            return String(localized: "\(whole) kg")
        }
        return String(localized: "\(whole).5 kg")
    }

    /// "40 kg \u{00D7} 10", or "40 kg \u{00D7} 10 | 10" when the exercise is unilateral,
    /// or "BW \u{00D7} 10" for a bodyweight set.
    static func setString(weightHalfKilos: Int?, reps: Int, repsRight: Int?) -> String {
        let weight = weightString(halfKilos: weightHalfKilos)
        guard let repsRight else {
            return String(localized: "\(weight) \(timesSign) \(reps)")
        }
        return String(localized: "\(weight) \(timesSign) \(reps) | \(repsRight)")
    }

    /// Convenience for a stored entry.
    static func setString(for entry: Entry) -> String {
        setString(
            weightHalfKilos: entry.weightHalfKilos,
            reps: entry.reps,
            repsRight: entry.repsRight
        )
    }

    /// "Never", "Today", "Yesterday", "3 days ago", "2 weeks ago", "5 months ago",
    /// "2 years ago". Computed from calendar day differences, never from elapsed seconds
    /// (PLAN.md pitfall 9): a set logged five minutes before midnight is "Yesterday" the
    /// next morning, not "Today".
    static func relativeDayString(
        from date: Date?,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        guard let date else { return String(localized: "Never") }

        let then = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: then, to: today).day ?? 0

        if days <= 0 { return String(localized: "Today") }
        if days == 1 { return String(localized: "Yesterday") }
        if days < 14 { return String(localized: "\(days) days ago") }
        if days < 56 {
            let weeks = days / 7
            return String(localized: "\(weeks) weeks ago")
        }

        let months = calendar.dateComponents([.month], from: then, to: today).month ?? (days / 30)
        if months < 12 {
            if months <= 1 { return String(localized: "1 month ago") }
            return String(localized: "\(months) months ago")
        }

        let years = months / 12
        if years <= 1 { return String(localized: "1 year ago") }
        return String(localized: "\(years) years ago")
    }

    /// Absolute date + time for the history list, e.g. "5 Sep 2026 at 09:41".
    static func absoluteDateTimeString(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened))
    }
}
