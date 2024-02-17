//
//  LoginItem.swift
//  Aware
//
//  Created by Joshua Peek on 2/16/24.
//

#if canImport(ServiceManagement)

import ServiceManagement

class LoginItem: ObservableObject {
    let appService: SMAppService

    static let mainApp = LoginItem(.mainApp)

    init(_ appService: SMAppService) {
        self.appService = appService
    }

    var isEnabled: Bool {
        get { appService.status == .enabled }
        set {
            objectWillChange.send()
            changeError = nil
            do {
                if newValue {
                    try appService.register()
                } else {
                    try appService.unregister()
                }
            } catch {
                changeError = error
            }
        }
    }

    var changeError: Error?
}

#endif
