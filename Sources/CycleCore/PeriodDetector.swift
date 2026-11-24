import Foundation

/// Turns raw "there was flow on this day" samples into period start dates.
///
/// Health data is treated as a hint: stray single days are tolerated, and a new
/// period only begins after a real gap.
public enum PeriodDetector {
    /// A break of more than this many days between flow days starts a new period.
    public static let maxGapWithinPeriod = 2
    /// Two starts closer than this are treated as the same period (spotting, late logging).
    public static let minDaysBetweenStarts = 10

    /// - Parameter flowDays: any dates on which flow was recorded, in any order, duplicates allowed.
    /// - Returns: start-of-day dates of each detected period, ascending.
    public static func periodStarts(fromFlowDays flowDays: [Date], calendar: Calendar = .current) -> [Date] {
        let days = Array(Set(flowDays.map { calendar.startOfDay(for: $0) })).sorted()
        var starts: [Date] = []
        var previous: Date?
        for day in days {
            defer { previous = day }
            guard let prev = previous, let lastStart = starts.last else {
                starts.append(day)
                continue
            }
            let gap = calendar.dateComponents([.day], from: prev, to: day).day ?? 0
            let sinceStart = calendar.dateComponents([.day], from: lastStart, to: day).day ?? 0
            if gap > maxGapWithinPeriod && sinceStart >= minDaysBetweenStarts {
                starts.append(day)
            }
        }
        return starts
    }

    /// Merges starts from several sources (Health, manual logs), collapsing near-duplicates.
    public static func mergeStarts(_ groups: [Date]..., calendar: Calendar = .current) -> [Date] {
        let all = Array(Set(groups.flatMap { $0 }.map { calendar.startOfDay(for: $0) })).sorted()
        var merged: [Date] = []
        for day in all {
            if let last = merged.last,
               (calendar.dateComponents([.day], from: last, to: day).day ?? 0) < minDaysBetweenStarts {
                continue
            }
            merged.append(day)
        }
        return merged
    }
}
