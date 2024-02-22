//
//  ProtectedDataAvailablity.swift
//  Aware
//
//  Created by Joshua Peek on 2/18/24.
//

#if canImport(UIKit)

import UIKit

@Observable class ProtectedDataAvailablity {
    var isAvailable: Bool = true

    private var availableObserver: NSObjectProtocol?
    private var unavailableObserver: NSObjectProtocol?

    init() {
        let notificationCenter = NotificationCenter.default

        isAvailable = true

        availableObserver = notificationCenter.addObserver(forName: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil, queue: .main) { [weak self] _ in
            assert(self != nil)
            assert(Thread.isMainThread)
            guard let self = self else { return }
            if self.isAvailable != true {
                self.isAvailable = true
            }
        }

        unavailableObserver = notificationCenter.addObserver(forName: UIApplication.protectedDataWillBecomeUnavailableNotification, object: nil, queue: .main) { [weak self] _ in
            assert(self != nil)
            assert(Thread.isMainThread)
            guard let self = self else { return }
            if self.isAvailable != false {
                self.isAvailable = false
            }
        }
    }

    deinit {
        if let availableObserver {
            NotificationCenter.default.removeObserver(availableObserver)
        }
        if let unavailableObserver {
            NotificationCenter.default.removeObserver(unavailableObserver)
        }
    }
}

#endif
