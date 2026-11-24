import Foundation
import CloudKit

/// Which role this install plays, plus the plumbing that system callbacks need to reach the stores.
@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published var role: Role? {
        didSet {
            guard role != oldValue else { return }
            SnapshotStore.shared.role = role
            // Each role keeps its own glance; never carry one over.
            SnapshotStore.shared.save(nil)
        }
    }

    let sharer = SharerStore()
    let viewer = ViewerStore()

    private init() {
        role = SnapshotStore.shared.role
    }

    /// Accepting an invite makes this install a Viewer.
    func acceptShare(_ metadata: CKShare.Metadata) {
        role = .viewer
        Task { await viewer.accept(metadata) }
    }

    func refresh() async {
        switch role {
        case .sharer: await sharer.refresh()
        case .viewer: await viewer.refresh()
        case nil: break
        }
    }
}
