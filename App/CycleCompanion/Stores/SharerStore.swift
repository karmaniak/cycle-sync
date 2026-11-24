import Foundation
import CloudKit
import CycleCore

/// Everything the Sharer's side of the app knows and does.
/// Health data and notes stay here; only `SnapshotBuilder` output is ever published.
@MainActor
final class SharerStore: ObservableObject {
    private enum Key {
        static let manualStarts = "sharer.manualStarts"
        static let typicalLength = "sharer.typicalCycleLength"
        static let periodLength = "sharer.periodLength"
        static let detail = "sharer.detail"
        static let paused = "sharer.paused"
        static let tone = "sharer.tone"
        static let sharingEnabled = "sharer.sharingEnabled"
        static let healthRequested = "sharer.healthRequested"
        static let cardDismissedDay = "sharer.checkInCardDismissedDay"
    }

    // MARK: Published state (read by views)

    @Published private(set) var estimate: CycleEstimate?
    @Published private(set) var healthStarts: [Date] = []
    @Published private(set) var manualStarts: [Date]
    /// nil means "learn from my history".
    @Published private(set) var typicalCycleLength: Int?
    @Published private(set) var periodLength: Int
    @Published private(set) var detail: ShareDetail
    @Published private(set) var isPaused: Bool
    @Published private(set) var tone: CheckInTone
    /// True once an invite has been created and not stopped.
    @Published private(set) var isSharing: Bool
    @Published private(set) var viewerCount = 0
    @Published private(set) var healthConnected: Bool
    @Published private(set) var showsCheckInCard = false
    @Published private(set) var iCloudAvailable = true
    @Published var displayOptions: Glance.Options {
        didSet { snapshots.options = displayOptions }
    }
    /// A friendly error line to show briefly, or nil.
    @Published var errorMessage: String?

    var isHealthAvailable: Bool { health.isAvailable }

    /// All known period starts, newest first, for the history list.
    var allStarts: [Date] {
        PeriodDetector.mergeStarts(healthStarts, manualStarts).reversed()
    }

    /// Exactly what a Viewer would receive right now, for the "their view" preview.
    var previewSnapshot: SharedSnapshot { makeSnapshot(detail: detail, paused: isPaused) }

    // MARK: Dependencies

    private let defaults: UserDefaults
    private let snapshots: SnapshotStore
    private let health = HealthKitService()
    private let cloud = CloudSharingService()
    private let notifier = CheckInNotifier()
    private var observing = false

    init(defaults: UserDefaults = .standard, snapshots: SnapshotStore = .shared) {
        self.defaults = defaults
        self.snapshots = snapshots
        let stored = defaults.array(forKey: Key.manualStarts) as? [Date] ?? []
        manualStarts = stored.sorted()
        let length = defaults.integer(forKey: Key.typicalLength)
        typicalCycleLength = length == 0 ? nil : length
        let period = defaults.integer(forKey: Key.periodLength)
        periodLength = period == 0 ? CycleEngine.defaultPeriodLength : period
        detail = defaults.string(forKey: Key.detail).flatMap(ShareDetail.init(rawValue:)) ?? .dayAndPhase
        isPaused = defaults.bool(forKey: Key.paused)
        tone = defaults.string(forKey: Key.tone).flatMap(CheckInTone.init(rawValue:)) ?? .silent
        isSharing = defaults.bool(forKey: Key.sharingEnabled)
        healthConnected = defaults.bool(forKey: Key.healthRequested)
        displayOptions = snapshots.options
        recompute()
    }

    // MARK: Refresh

    /// Re-reads Health, recomputes, republishes if sharing, and replans the check-in.
    func refresh() async {
        if healthConnected {
            let since = Calendar.current.date(byAdding: .month, value: -12, to: .now) ?? .distantPast
            if let days = try? await health.flowDays(since: since) {
                healthStarts = PeriodDetector.periodStarts(fromFlowDays: days)
            }
            if !observing {
                observing = true
                health.observeChanges { [weak self] in
                    Task { await self?.refresh() }
                }
            }
        }
        recompute()
        iCloudAvailable = await cloud.isAccountAvailable()
        if isSharing {
            await publish()
            viewerCount = await cloud.viewerCount()
        }
        await notifier.reschedule(estimate.flatMap {
            CheckInPlanner.notificationPlan(estimate: $0, tone: tone, now: .now)
        })
    }

    private func recompute() {
        let starts = PeriodDetector.mergeStarts(healthStarts, manualStarts)
        estimate = CycleEngine().estimate(
            periodStarts: starts,
            typicalCycleLength: typicalCycleLength,
            periodLength: periodLength,
            today: .now
        )
        // Her own widget always shows the full picture; it never leaves this device.
        snapshots.save(makeSnapshot(detail: .dayAndPhase, paused: false))

        let todayKey = SharedSnapshot.dayKey(.now)
        let dismissedToday = defaults.string(forKey: Key.cardDismissedDay) == todayKey
        showsCheckInCard = !dismissedToday && (estimate.map {
            CheckInPlanner.shouldInviteInApp(estimate: $0, tone: tone, today: .now)
        } ?? false)
    }

    private func makeSnapshot(detail: ShareDetail, paused: Bool) -> SharedSnapshot {
        SnapshotBuilder.make(
            periodStarts: PeriodDetector.mergeStarts(healthStarts, manualStarts),
            typicalCycleLength: typicalCycleLength,
            periodLength: periodLength,
            detail: detail,
            paused: paused,
            now: .now
        )
    }

    private func publish() async {
        do {
            try await cloud.publish(previewSnapshot)
        } catch {
            errorMessage = Copy.Sharing.genericError
        }
    }

    // MARK: Health

    func connectHealth() async {
        do {
            try await health.requestAuthorization()
            healthConnected = true
            defaults.set(true, forKey: Key.healthRequested)
            await refresh()
        } catch {
            errorMessage = Copy.Sharing.genericError
        }
    }

    // MARK: Notes

    func logPeriodStart(on date: Date = .now) async {
        let day = Calendar.current.startOfDay(for: date)
        guard day <= .now, !manualStarts.contains(day) else { return }
        manualStarts = (manualStarts + [day]).sorted()
        defaults.set(manualStarts, forKey: Key.manualStarts)
        await refresh()
    }

    func isManual(_ date: Date) -> Bool { manualStarts.contains(date) }

    func removeManualStart(_ date: Date) async {
        manualStarts.removeAll { $0 == date }
        defaults.set(manualStarts, forKey: Key.manualStarts)
        await refresh()
    }

    /// Hides the in-app card for today. This is not an answer and is recorded nowhere else.
    func dismissCheckInCard() {
        defaults.set(SharedSnapshot.dayKey(.now), forKey: Key.cardDismissedDay)
        showsCheckInCard = false
    }

    // MARK: Settings

    func setTypicalCycleLength(_ length: Int?) async {
        typicalCycleLength = length
        defaults.set(length ?? 0, forKey: Key.typicalLength)
        await refresh()
    }

    func setPeriodLength(_ length: Int) async {
        periodLength = length
        defaults.set(length, forKey: Key.periodLength)
        await refresh()
    }

    func setTone(_ newTone: CheckInTone) async {
        tone = newTone
        defaults.set(newTone.rawValue, forKey: Key.tone)
        await notifier.requestPermissionIfNeeded(for: newTone)
        await refresh()
    }

    // MARK: Sharing

    func setDetail(_ newDetail: ShareDetail) async {
        detail = newDetail
        defaults.set(newDetail.rawValue, forKey: Key.detail)
        if isSharing { await publish() }
    }

    func setPaused(_ paused: Bool) async {
        isPaused = paused
        defaults.set(paused, forKey: Key.paused)
        if isSharing { await publish() }
    }

    /// Creates (or fetches) the share to present in the system invite sheet.
    func prepareShare() async -> (CKShare, CKContainer)? {
        do {
            let share = try await cloud.prepareShare(publishing: previewSnapshot)
            isSharing = true
            defaults.set(true, forKey: Key.sharingEnabled)
            return (share, cloud.container)
        } catch {
            errorMessage = await cloud.isAccountAvailable() ? Copy.Sharing.genericError : Copy.Sharing.iCloudUnavailable
            return nil
        }
    }

    /// Call when the system sharing sheet closes, to pick up added or removed people.
    func sharingSheetDidClose() async {
        viewerCount = await cloud.viewerCount()
    }

    /// Revokes access for everyone and deletes the shared summary from iCloud.
    func stopSharing() async {
        do {
            try await cloud.stopSharing()
            isSharing = false
            viewerCount = 0
            defaults.set(false, forKey: Key.sharingEnabled)
        } catch {
            errorMessage = Copy.Sharing.genericError
        }
    }

    /// Removes everything this app stored, on device and in iCloud. Apple Health is untouched.
    func deleteEverything() async {
        await stopSharing()
        guard !isSharing else { return }
        manualStarts = []
        healthStarts = []
        healthConnected = false
        for key in [Key.manualStarts, Key.typicalLength, Key.periodLength, Key.detail, Key.paused,
                    Key.tone, Key.healthRequested, Key.cardDismissedDay] {
            defaults.removeObject(forKey: key)
        }
        typicalCycleLength = nil
        periodLength = CycleEngine.defaultPeriodLength
        detail = .dayAndPhase
        isPaused = false
        tone = .silent
        await notifier.reschedule(nil)
        estimate = nil
        showsCheckInCard = false
        snapshots.save(nil)
    }
}
