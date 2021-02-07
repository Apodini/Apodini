//
//  Application+FCM.swift
//
//
//  Created by Tim Gymnich on 30.12.20.
//

import Apodini
import ApodiniVaporSupport
import FCM

extension Application {
    /// Firebase Cloud Messaging.
    public var fcm: FCM {
        // Stores FCM in app storage otherwise a warning will be logged.
        if let storedFcm = self.storage[ConfigurationKey.self] {
            return storedFcm
        }
        let newFcm = FCM(app: self)
        self.storage[ConfigurationKey.self] = newFcm

        return newFcm
    }

    struct ConfigurationKey: StorageKey {
        typealias Value = FCM
    }
}

extension FCM {
    init(app: Application) {
        self.init(application: app.vapor.app)
    }
}
