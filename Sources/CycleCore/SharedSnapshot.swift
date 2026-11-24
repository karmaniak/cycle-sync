import Foundation

/// The only thing that ever leaves the Sharer's device.
///
/// A handful of already-redacted day summaries: no raw Health samples, no period
/// dates, no cycle length, no check-in activity. Fields the Sharer has not chosen
/// to share are absent from the payload itself, not merely hidden by the Viewer's UI.
public struct SharedSnapshot: Codable, Equatable, Sendable {
    public enum Status: String, Codable, Sendable {
        case active, paused
    }

    public struct Day: Codable, Equatable, Sendable {
        /// Calendar day in the Sharer's own calendar, "yyyy-MM-dd".
        public let date: String
        public let cycleDay: Int?
        public let phase: Phase?
        public let confidence: Confidence?
        /// 0...1 on the colour scale; nil when the engine has no honest estimate.
        public let color: Double?

        public init(date: String, cycleDay: Int?, phase: Phase?, confidence: Confidence?, color: Double?) {
            self.date = date
            self.cycleDay = cycleDay
            self.phase = phase
            self.confidence = confidence
            self.color = color
        }
    }

    public static let currentVersion = 1
    /// How many days ahead are included, so the Viewer's widget keeps moving
    /// even if the Sharer does not open the app for a while.
    public static let horizonDays = 7

    public var version: Int
    public var status: Status
    public var detail: ShareDetail
    public var updatedAt: Date
    public var days: [Day]

    public init(version: Int = SharedSnapshot.currentVersion, status: Status, detail: ShareDetail, updatedAt: Date, days: [Day]) {
        self.version = version
        self.status = status
        self.detail = detail
        self.updatedAt = updatedAt
        self.days = days
    }

    /// A paused snapshot carries nothing but the fact that sharing is paused.
    public static func paused(detail: ShareDetail, now: Date) -> SharedSnapshot {
        SharedSnapshot(status: .paused, detail: detail, updatedAt: now, days: [])
    }

    public func day(for date: Date, calendar: Calendar = .current) -> Day? {
        let key = Self.dayKey(date, calendar: calendar)
        return days.first { $0.date == key }
    }

    public static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    public static func decode(_ data: Data) throws -> SharedSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SharedSnapshot.self, from: data)
    }
}

/// Builds the redacted snapshot on the Sharer's device.
public enum SnapshotBuilder {
    public static func make(
        periodStarts: [Date],
        typicalCycleLength: Int?,
        periodLength: Int = CycleEngine.defaultPeriodLength,
        detail: ShareDetail,
        paused: Bool,
        now: Date,
        calendar: Calendar = .current,
        horizonDays: Int = SharedSnapshot.horizonDays
    ) -> SharedSnapshot {
        guard !paused else { return .paused(detail: detail, now: now) }
        let engine = CycleEngine(calendar: calendar)
        let today = calendar.startOfDay(for: now)
        let days: [SharedSnapshot.Day] = (0..<max(horizonDays, 1)).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: today)!
            let estimate = engine.estimate(
                periodStarts: periodStarts,
                typicalCycleLength: typicalCycleLength,
                periodLength: periodLength,
                today: date
            )
            return redact(estimate, date: date, detail: detail, calendar: calendar)
        }
        return SharedSnapshot(status: .active, detail: detail, updatedAt: now, days: days)
    }

    static func redact(_ estimate: CycleEstimate?, date: Date, detail: ShareDetail, calendar: Calendar) -> SharedSnapshot.Day {
        let key = SharedSnapshot.dayKey(date, calendar: calendar)
        guard let estimate else {
            return .init(date: key, cycleDay: nil, phase: nil, confidence: nil, color: nil)
        }
        // Two decimals is plenty for a colour and avoids leaking a precise day through it.
        let color = (estimate.colorPosition * 100).rounded() / 100
        switch detail {
        case .dayAndPhase:
            return .init(date: key, cycleDay: estimate.cycleDay, phase: estimate.phase, confidence: estimate.confidence, color: color)
        case .phaseOnly:
            return .init(date: key, cycleDay: nil, phase: estimate.phase, confidence: estimate.confidence, color: color)
        case .colorOnly:
            // Coarser still: the Viewer gets a shade, not a countdown.
            return .init(date: key, cycleDay: nil, phase: nil, confidence: nil, color: (estimate.colorPosition * 10).rounded() / 10)
        }
    }
}
