//
//  Application+APNS.swift
//  
//
//  Created by Tim Gymnich on 23.12.20.
//

import APNS


extension Application {
    /// Holds the APNS Configuration
    public var apns: APNS {
        .init(application: self)
    }

    /// Holds the APNS Configuration
    public struct APNS {
        struct ConfigurationKey: StorageKey {
            typealias Value = APNSwiftConfiguration
        }

        /// APNS Configuration
        public var configuration: APNSwiftConfiguration? {
            get {
                self.application.storage[ConfigurationKey.self]
            }
            nonmutating set {
                self.application.storage[ConfigurationKey.self] = newValue
            }
        }

        let application: Application
    }
}
