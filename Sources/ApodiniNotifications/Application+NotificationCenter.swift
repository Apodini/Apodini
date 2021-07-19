//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini

extension Application {
    /// Holds the `NotificationCenter` of the web service.
    public var notificationCenter: NotificationCenter {
        if let storedNotificationCenter = self.storage[NotificationCenterKey.self] {
            return storedNotificationCenter
        }
        let newNotificationCenter = NotificationCenter(app: self)
        self.storage[NotificationCenterKey.self] = newNotificationCenter
        
        return newNotificationCenter
    }
    
    struct NotificationCenterKey: StorageKey {
        typealias Value = NotificationCenter
    }
}
