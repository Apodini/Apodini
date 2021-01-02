//
//  File.swift
//  
//
//  Created by Tim Gymnich on 30.12.20.
//

import Foundation
import struct FCM.FCMConfiguration

/// renamed FCM.FCMConfiguration due to name clash with struct FCM
public typealias FCMConfig = FCM.FCMConfiguration

extension Application {
    /// Firebase Cloud Messaging
    public var fcm: FCM {
        .init(application: self)
    }

    /// Firebase Cloud Messaging
    public struct FCM {
        struct ConfigurationKey: StorageKey {
            // swiftlint:disable nesting
            typealias Value = FCMConfig
        }

        /// FCM Configuration
        public var configuration: FCMConfig? {
            get {
                application.storage[ConfigurationKey.self]
            }
            nonmutating set {
                application.storage[ConfigurationKey.self] = newValue
            }
        }

        let application: Application
    }
}
