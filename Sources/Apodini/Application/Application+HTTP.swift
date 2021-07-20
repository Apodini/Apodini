//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
//
// This code is based on the Vapor project: https://github.com/vapor/vapor
//
// SPDX-FileCopyrightText: 2020 Qutheory, LLC
//
// SPDX-License-Identifier: MIT
//               

import NIOSSL


/// The http najor version
public enum HTTPVersionMajor: Equatable, Hashable {
    case one
    case two
}


/// BindAddress
public enum BindAddress: Equatable {
    case hostname(_ hostname: String?, port: Int?)
    case unixDomainSocket(path: String)
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
            var address: BindAddress?


            // swiftlint:disable discouraged_optional_collection
            init(
                supportVersions: Set<HTTPVersionMajor>? = nil,
                tlsConfiguration: TLSConfiguration? = nil,
                address: BindAddress? = nil
            ) {
                if let supportVersions = supportVersions {
                    self.supportVersions = supportVersions
                } else {
                    self.supportVersions = tlsConfiguration == nil ? [.one] : [.one, .two]
                }
                self.tlsConfiguration = tlsConfiguration
                self.address = address
            }
        }

        struct Key: StorageKey {
            // swiftlint:disable nesting
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

        /// HTTP Server address
        public var address: BindAddress? {
            get { storage.address }
            set { storage.address = newValue }
        }

        init(application: Application) {
            self.application = application
        }

        func initialize() {
            self.application.storage[Key.self] = .init()
        }
    }
}
