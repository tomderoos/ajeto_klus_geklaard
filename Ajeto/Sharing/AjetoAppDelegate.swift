import UIKit
import CloudKit

/// UIApplicationDelegate + scene-delegate zodat we CKShare-uitnodigingen
/// kunnen ontvangen. iOS levert een geaccepteerde share aan via
/// `windowScene(_:userDidAcceptCloudKitShareWith:)`; SwiftUI's WindowGroup
/// biedt hier zelf geen directe modifier voor, dus hebben we een
/// AppDelegate + SceneDelegate nodig.
final class AjetoAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = AjetoSceneDelegate.self
        return config
    }
}

final class AjetoSceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?

    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        Task { @MainActor in
            do {
                try await HouseholdSharingService.shared
                    .acceptShareInvitation(with: cloudKitShareMetadata)
                NotificationCenter.default.post(
                    name: .ajetoShareAccepted,
                    object: nil,
                    userInfo: ["share": cloudKitShareMetadata]
                )
            } catch {
                NotificationCenter.default.post(
                    name: .ajetoShareAcceptFailed,
                    object: nil,
                    userInfo: ["error": error]
                )
            }
        }
    }
}

extension Notification.Name {
    static let ajetoShareAccepted     = Notification.Name("nl.tomderoos.Ajeto.shareAccepted")
    static let ajetoShareAcceptFailed = Notification.Name("nl.tomderoos.Ajeto.shareAcceptFailed")
}
