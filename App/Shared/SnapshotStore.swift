import Foundation
import WidgetKit
import CycleCore

/// The App Group container the app writes and the widget reads.
/// Holds only the already-redacted summary and a few display preferences.
struct SnapshotStore {
    private enum Key {
        static let snapshot = "snapshot"
        static let role = "role"
        static let highContrast = "highContrast"
        static let showsMessage = "showsMessage"
    }

    static let shared = SnapshotStore()
    let defaults: UserDefaults

    init(defaults: UserDefaults = UserDefaults(suiteName: AppIdentifiers.appGroup) ?? .standard) {
        self.defaults = defaults
    }

    var role: Role? {
        get { defaults.string(forKey: Key.role).flatMap(Role.init(rawValue:)) }
        nonmutating set { defaults.set(newValue?.rawValue, forKey: Key.role) }
    }

    var options: Glance.Options {
        get {
            Glance.Options(
                highContrast: defaults.bool(forKey: Key.highContrast),
                showsMessage: defaults.object(forKey: Key.showsMessage) as? Bool ?? true
            )
        }
        nonmutating set {
            defaults.set(newValue.highContrast, forKey: Key.highContrast)
            defaults.set(newValue.showsMessage, forKey: Key.showsMessage)
            reloadWidgets()
        }
    }

    func load() -> SharedSnapshot? {
        guard let data = defaults.data(forKey: Key.snapshot) else { return nil }
        return try? SharedSnapshot.decode(data)
    }

    /// Saves (or, with nil, clears) the snapshot and asks widgets to redraw.
    func save(_ snapshot: SharedSnapshot?, reload: Bool = true) {
        if let snapshot, let data = try? snapshot.encoded() {
            defaults.set(data, forKey: Key.snapshot)
        } else {
            defaults.removeObject(forKey: Key.snapshot)
        }
        if reload { reloadWidgets() }
    }

    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
