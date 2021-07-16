//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
