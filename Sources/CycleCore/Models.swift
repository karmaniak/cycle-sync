import Foundation

/// The four phases the app talks about. Raw values are part of the synced payload.
public enum Phase: String, Codable, CaseIterable, Sendable {
    case menstrual, follicular, ovulation, luteal
}

/// How much the engine trusts its own estimate. Always shown, never hidden.
public enum Confidence: String, Codable, CaseIterable, Comparable, Sendable {
    case low, medium, high

    private var rank: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }

    public static func < (lhs: Confidence, rhs: Confidence) -> Bool { lhs.rank < rhs.rank }
}

/// What the Sharer chooses to let a Viewer see. Each level includes the ones after it.
public enum ShareDetail: String, Codable, CaseIterable, Sendable {
    /// Day number, phase and colour.
    case dayAndPhase
    /// Phase and colour, no day number.
    case phaseOnly
    /// Only the colour.
    case colorOnly
}

/// Check-in notification tone, picked by the Sharer. Silent is the default.
public enum CheckInTone: String, Codable, CaseIterable, Sendable {
    /// No notification at all. The invitation only appears inside the app.
    case silent
    /// One quiet notification, no sound, two days after the expected window.
    case gentle
    /// One ordinary notification, one day after the expected window.
    case regular
}

/// The result of running the engine for one day.
public struct CycleEstimate: Equatable, Sendable {
    /// 1-based day of the current cycle.
    public let cycleDay: Int
    public let phase: Phase
    public let confidence: Confidence
    /// Cycle length the estimate is built on, in days.
    public let cycleLength: Int
    /// Period length the estimate is built on, in days.
    public let periodLength: Int
    /// Start of the most recent period (start of day).
    public let lastPeriodStart: Date
    /// Soft range for the next period start. Never a single day.
    public let nextStartWindow: ClosedRange<Date>
    /// Plus/minus days around the central expected start.
    public let uncertaintyDays: Int
    /// True once the expected window plus the grace period has passed with no new start.
    /// Sharer-only; never synced.
    public let isRunningBehind: Bool
    /// Position on the white-to-deep-red scale, 0...1.
    public let colorPosition: Double
}
