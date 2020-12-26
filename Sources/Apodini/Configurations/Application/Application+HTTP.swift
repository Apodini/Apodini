//
//  Application+HTTP.swift
//  
//
//  Created by Tim Gymnich on 26.12.20.
//

import NIOSSL

/// The http najor version
public enum HTTPVersionMajor: Equatable, Hashable {
    case one
    case two
}

extension Application {

    /// Used to keep track of http related configuration
    public var http: HTTP {
        .init(application: self)
    }

    /// Used to keep track of http related configuration
    public final class HTTP {
        final class Storage {
            var supportVersions: Set<HTTPVersionMajor>
            var tlsConfiguration: TLSConfiguration?

            init(
                supportVersions: Set<HTTPVersionMajor>? = nil,
                tlsConfiguration: TLSConfiguration? = nil
            ) {
                if let supportVersions = supportVersions {
                    self.supportVersions = supportVersions
                } else {
                    self.supportVersions = tlsConfiguration == nil ? [.one] : [.one, .two]
                }
                self.tlsConfiguration = tlsConfiguration
            }
        }

        struct Key: StorageKey {
            typealias Value = Storage
        }

        let application: Application

        var storage: Storage {
            if self.application.storage[Key.self] == nil {
                self.initialize()
            }
            // swiftlint:disable force_unwrapping
            return self.application.storage[Key.self]!
        }

        /// Supported http major versions
        public var supportVersions: Set<HTTPVersionMajor> {
            get { storage.supportVersions }
            set { storage.supportVersions = newValue }
        }

        /// TLS configuration
        public var tlsConfiguration: TLSConfiguration? {
            get { storage.tlsConfiguration }
            set { storage.tlsConfiguration = newValue }
        }

        init(application: Application) {
            self.application = application
        }

        func initialize() {
            self.application.storage[Key.self] = .init()
        }
    }
}
