import SwiftUI
import UIKit
import CloudKit
import CycleCore

/// The system invite sheet. Invite-only and read-only: the options a Viewer could
/// use to get more access are simply not offered.
struct CloudSharingSheet: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    var onClose: () -> Void = {}

    func makeCoordinator() -> Coordinator { Coordinator(onClose: onClose) }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowPrivate, .allowReadOnly]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: UICloudSharingController, context: Context) {}

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let onClose: () -> Void
        init(onClose: @escaping () -> Void) { self.onClose = onClose }

        func itemTitle(for csc: UICloudSharingController) -> String? { Copy.Sharing.shareTitle }
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) { onClose() }
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) { onClose() }
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) { onClose() }
    }
}
