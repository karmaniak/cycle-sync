import Foundation

/// When (and whether) to invite the Sharer to note a period start.
///
/// Rules from the design brief: never on the predicted day itself, wait one to
/// two days past the soft window, invitation wording, silent by default. A
/// dismissal is never recorded as an answer; nothing here is ever synced.
public enum CheckInPlanner {
    public struct Plan: Equatable, Sendable {
        public let fireDate: Date
        public let tone: CheckInTone
    }

    /// Hour of day (local) a notification is delivered. Mid-morning, not first thing.
    public static let deliveryHour = 10

    static func waitDays(for tone: CheckInTone) -> Int {
        tone == .regular ? 1 : 2
    }

    /// The day from which the in-app invitation card may appear.
    public static func invitationDate(for estimate: CycleEstimate, tone: CheckInTone, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: waitDays(for: tone), to: estimate.nextStartWindow.upperBound)!
    }

    /// Whether the app should show its quiet "anything to note?" card today.
    public static func shouldInviteInApp(estimate: CycleEstimate, tone: CheckInTone, today: Date, calendar: Calendar = .current) -> Bool {
        calendar.startOfDay(for: today) >= invitationDate(for: estimate, tone: tone, calendar: calendar)
    }

    /// The single notification to schedule, or `nil` when none should be sent
    /// (silent tone, or its moment has already passed: we never send a late nudge).
    public static func notificationPlan(estimate: CycleEstimate, tone: CheckInTone, now: Date, calendar: Calendar = .current) -> Plan? {
        guard tone != .silent else { return nil }
        let day = invitationDate(for: estimate, tone: tone, calendar: calendar)
        guard let fire = calendar.date(bySettingHour: deliveryHour, minute: 0, second: 0, of: day), fire > now else {
            return nil
        }
        return Plan(fireDate: fire, tone: tone)
    }
}
