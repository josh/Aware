//
//  NotificationName+Nonisolated.swift
//  Aware
//
//  Created by Joshua Peek on 3/24/24.
//

#if canImport(UIKit)
import UIKit

// Seems like an SDK bug these notification name constants are marked as isolated to the main actor.
extension UIApplication {
    nonisolated static let nonisolatedDidEnterBackgroundNotification = Notification.Name(
        "UIApplicationDidEnterBackgroundNotification")
    nonisolated static let nonisolatedWillEnterForegroundNotification = Notification.Name(
        "UIApplicationWillEnterForegroundNotification")
}

#endif
