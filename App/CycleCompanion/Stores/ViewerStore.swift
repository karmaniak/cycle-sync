import Foundation
import CloudKit
import CycleCore

/// The Viewer's side: receives the shared summary and nothing else.
/// There is deliberately no way to ask for more from here.
@MainActor
final class ViewerStore: ObservableObject {
    @Published private(set) var snapshot: SharedSnapshot?
    @Published private(set) var isRefreshing = false
    @Published var displayOptions: Glance.Options {
        didSet { snapshots.options = displayOptions }
    }
    @Published var errorMessage: String?

    /// What to draw right now, in every state (not linked, paused, stale, uncertain, live).
    var content: GlanceContent {
        Glance.content(snapshot: snapshot, on: .now, options: displayOptions)
    }

    var isLinked: Bool { snapshot != nil }

    private let snapshots: SnapshotStore
    private let cloud = CloudSharingService()

    init(snapshots: SnapshotStore = .shared) {
        self.snapshots = snapshots
        snapshot = snapshots.load()
        displayOptions = snapshots.options
    }

    /// Pulls the latest summary. A revoked share comes back as nil and resets the widget to neutral.
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let fetched = try await cloud.fetchShared()
            snapshot = fetched
            snapshots.save(fetched)
            try? await cloud.subscribeToSharedChanges()
        } catch {
            // Keep showing what we have; the glance goes "catching up" on its own when it runs out.
        }
    }

    func accept(_ metadata: CKShare.Metadata) async {
        do {
            try await cloud.accept(metadata)
            await refresh()
        } catch {
            errorMessage = Copy.Sharing.genericError
        }
    }

    func unlink() async {
        do {
            try await cloud.leaveShared()
            snapshot = nil
            snapshots.save(nil)
        } catch {
            errorMessage = Copy.Sharing.genericError
        }
    }
}
