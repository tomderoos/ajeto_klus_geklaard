import SwiftUI
import CloudKit
import UIKit

/// SwiftUI-wrapper rond UICloudSharingController. Toont Apple's eigen
/// participants-sheet (à la Notes / Herinneringen) waarin de eigenaar
/// deelnemers kan uitnodigen, rechten kan zetten en de share weer kan
/// stoppen.
struct HouseholdShareController: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    var onEnd: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(share: share, onEnd: onEnd)
    }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowPrivate, .allowReadWrite]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let share: CKShare
        let onEnd: (() -> Void)?

        init(share: CKShare, onEnd: (() -> Void)?) {
            self.share = share
            self.onEnd = onEnd
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            share[CKShare.SystemFieldKey.title] as? String ?? "Huishouden"
        }

        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            // Netjes falen — een alert tonen zou fijner zijn, maar
            // UICloudSharingController biedt dat al zelf.
            onEnd?()
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            onEnd?()
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            onEnd?()
        }
    }
}
