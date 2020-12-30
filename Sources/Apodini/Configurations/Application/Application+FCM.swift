//
//  File.swift
//  
//
//  Created by Tim Gymnich on 30.12.20.
//

import Foundation
import FCM

extension Application {
    /// Firebase Cloud Messaging
    public var fcm: FCM {
        .init(application: self)
    }

    /// Firebase Cloud Messaging
    public struct FCM {
        struct ConfigurationKey: StorageKey {
            // swiftlint:disable nesting
            typealias Value = FCMConfiguration
        }

        /// FCM Configuration
        public var configuration: FCMConfiguration? {
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
