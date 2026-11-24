import Foundation

/// Pure, deterministic cycle maths. No HealthKit, no network, no clock of its own.
///
/// Give it period start dates and (optionally) the Sharer's typical cycle length;
/// it answers with a day, a phase, a confidence level and a soft range for the
/// next start. It never claims a single predicted date.
public struct CycleEngine: Sendable {
    public static let defaultCycleLength = 28
    public static let defaultPeriodLength = 5
    /// Intervals outside this range are ignored when learning the cycle length:
    /// shorter is usually spotting, longer usually means a period went unlogged.
    public static let plausibleCycleLengths = 15...60
    /// How many recent cycles feed the estimate.
    public static let historyWindow = 6
    /// Days after the expected window before "running a little behind" may be shown.
    public static let graceDays = 2
    /// Luteal phase length used to place ovulation, counted back from the next start.
    public static let lutealLength = 14

    public var calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// - Parameters:
    ///   - periodStarts: confirmed period start dates, any order.
    ///   - typicalCycleLength: the Sharer's own number, if she set one. Wins over history.
    ///   - periodLength: typical days of bleeding.
    ///   - today: the day to estimate for.
    /// - Returns: `nil` when there is nothing honest to say (no starts yet, or the
    ///   last start is so old a period has almost certainly gone unlogged).
    public func estimate(
        periodStarts: [Date],
        typicalCycleLength: Int? = nil,
        periodLength: Int = CycleEngine.defaultPeriodLength,
        today: Date
    ) -> CycleEstimate? {
        let todayStart = calendar.startOfDay(for: today)
        let starts = PeriodDetector.mergeStarts(periodStarts, calendar: calendar).filter { $0 <= todayStart }
        guard let lastStart = starts.last else { return nil }

        let intervals = recentIntervals(starts)
        let learned = median(intervals)
        let typical = typicalCycleLength.map { min(max($0, Self.plausibleCycleLengths.lowerBound), Self.plausibleCycleLengths.upperBound) }
        let length = typical ?? learned ?? Self.defaultCycleLength
        let period = min(max(periodLength, 1), 10)

        let cycleDay = days(from: lastStart, to: todayStart) + 1
        // Twice the cycle length with no new start: a log is missing, not a long cycle.
        guard cycleDay <= length * 2 else { return nil }

        let spread = standardDeviation(intervals)
        var confidence = baseConfidence(intervalCount: intervals.count, spread: spread, hasTypical: typical != nil)
        let uncertainty = uncertaintyDays(confidence: confidence, spread: spread)

        // Past the soft window without a new start: trust the phase a notch less.
        if cycleDay > length + uncertainty {
            confidence = confidence == .high ? .medium : .low
        }

        let expected = calendar.date(byAdding: .day, value: length, to: lastStart)!
        let windowStart = calendar.date(byAdding: .day, value: -uncertainty, to: expected)!
        let windowEnd = calendar.date(byAdding: .day, value: uncertainty, to: expected)!
        let behindFrom = calendar.date(byAdding: .day, value: Self.graceDays, to: windowEnd)!

        return CycleEstimate(
            cycleDay: cycleDay,
            phase: Self.phase(cycleDay: cycleDay, cycleLength: length, periodLength: period),
            confidence: confidence,
            cycleLength: length,
            periodLength: period,
            lastPeriodStart: lastStart,
            nextStartWindow: windowStart...windowEnd,
            uncertaintyDays: uncertainty,
            isRunningBehind: todayStart > behindFrom,
            colorPosition: ColorScale.position(cycleDay: cycleDay, cycleLength: length, periodLength: period)
        )
    }

    // MARK: Phase

    /// The estimated ovulation day (1-based), roughly fourteen days before the next start.
    /// Very short cycles keep at least one follicular day after the period.
    public static func ovulationDay(cycleLength: Int, periodLength: Int) -> Int {
        max(cycleLength - lutealLength, periodLength + 3)
    }

    public static func phase(cycleDay: Int, cycleLength: Int, periodLength: Int) -> Phase {
        if cycleDay <= periodLength { return .menstrual }
        let ovulation = ovulationDay(cycleLength: cycleLength, periodLength: periodLength)
        if cycleDay < ovulation - 1 { return .follicular }
        if cycleDay <= ovulation + 1 { return .ovulation }
        return .luteal
    }

    // MARK: Learning from history

    func recentIntervals(_ sortedStarts: [Date]) -> [Int] {
        guard sortedStarts.count > 1 else { return [] }
        let all = zip(sortedStarts, sortedStarts.dropFirst()).map { days(from: $0, to: $1) }
        return Array(all.filter { Self.plausibleCycleLengths.contains($0) }.suffix(Self.historyWindow))
    }

    func baseConfidence(intervalCount: Int, spread: Double?, hasTypical: Bool) -> Confidence {
        guard intervalCount >= 2, let spread else {
            // Too little history to judge regularity. Her own number is worth something.
            return hasTypical ? .medium : .low
        }
        if spread > 4 { return .low }
        if intervalCount >= 3 && spread <= 1.5 { return .high }
        return .medium
    }

    func uncertaintyDays(confidence: Confidence, spread: Double?) -> Int {
        switch confidence {
        case .high: return 1
        case .medium: return max(2, Int((spread ?? 0).rounded(.up)))
        case .low: return min(10, max(4, Int(((spread ?? 0) * 1.5).rounded(.up))))
        }
    }

    // MARK: Small maths

    private func days(from: Date, to: Date) -> Int {
        calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    private func median(_ values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 1 { return sorted[mid] }
        return Int((Double(sorted[mid - 1] + sorted[mid]) / 2).rounded())
    }

    private func standardDeviation(_ values: [Int]) -> Double? {
        guard values.count >= 2 else { return nil }
        let mean = Double(values.reduce(0, +)) / Double(values.count)
        let variance = values.reduce(0.0) { $0 + pow(Double($1) - mean, 2) } / Double(values.count - 1)
        return variance.squareRoot()
    }
}
