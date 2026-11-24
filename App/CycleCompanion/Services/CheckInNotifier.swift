import Foundation
import UserNotifications
import CycleCore

/// Local check-in notifications, scheduled on the Sharer's device only.
/// At most one is ever pending. Dismissing it does nothing at all.
struct CheckInNotifier {
    static let categoryID = "CHECK_IN"
    static let logActionID = "LOG_PERIOD_START"
    private static let requestID = "check-in"

    private var center: UNUserNotificationCenter { .current() }

    func registerCategory() {
        let log = UNNotificationAction(identifier: Self.logActionID, title: Copy.CheckIn.actionLog, options: [])
        let category = UNNotificationCategory(identifier: Self.categoryID, actions: [log], intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
    }

    /// Asks for permission only when the Sharer has picked a tone that needs it.
    func requestPermissionIfNeeded(for tone: CheckInTone) async {
        guard tone != .silent else { return }
        _ = try? await center.requestAuthorization(options: tone == .regular ? [.alert, .sound] : [.alert])
    }

    /// Replaces any pending check-in with the given plan (or with nothing).
    func reschedule(_ plan: CheckInPlanner.Plan?) async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestID])
        guard let plan else { return }

        let content = UNMutableNotificationContent()
        content.title = Copy.CheckIn.title
        content.body = Copy.CheckIn.body
        content.categoryIdentifier = Self.categoryID
        switch plan.tone {
        case .regular:
            content.sound = .default
            content.interruptionLevel = .active
        case .gentle, .silent:
            content.sound = nil
            content.interruptionLevel = .passive
        }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: plan.fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: Self.requestID, content: content, trigger: trigger))
    }
}
