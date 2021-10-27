//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import Vapor


extension Vapor.Application {
    struct LifecycleHandler: Apodini.LifecycleHandler {
        var app: Vapor.Application

        func didBoot(_ application: Apodini.Application) throws {
            // HTTP2
            app.http.server.configuration.supportVersions = Set(application.httpConfiguration.supportVersions.map { version in
                switch version {
                case .one: return Vapor.HTTPVersionMajor.one
                case .two: return Vapor.HTTPVersionMajor.two
                }
            })
            app.http.server.configuration.tlsConfiguration = application.httpConfiguration.tlsConfiguration
            
            try app.server.start(address: Vapor.BindAddress(from: application.httpConfiguration.bindAddress))
            try app.boot()
        }

        func shutdown(_ application: Apodini.Application) throws {
            app.server.shutdown()
            app.shutdown()
        }
    }

    convenience init(from app: Apodini.Application, environment env: Vapor.Environment = .production) {
        self.init(env, .shared(app.eventLoopGroup))
        app.lifecycle.use(LifecycleHandler(app: self))
        self.routes.defaultMaxBodySize = "1mb"
        self.logger = app.logger
    }
}


public extension Apodini.Application {
    /// Configuration related to vapor.
    var vapor: VaporApp {
        .init(application: self)
    }

    /// Holds the APNS Configuration
    struct VaporApp {
        struct ConfigurationKey: Apodini.StorageKey {
            // swiftlint:disable nesting
            typealias Value = Vapor.Application
        }

        /// The shared vapor application instance.
        public var app: Vapor.Application {
            if self.application.storage[ConfigurationKey.self] == nil {
                self.initialize()
            }
            // swiftlint:disable force_unwrapping
            return self.application.storage[ConfigurationKey.self]!
        }

        func initialize() {
            self.application.storage[ConfigurationKey.self] = .init(from: application)
        }

        private let application: Apodini.Application

        init(application: Apodini.Application) {
            self.application = application
        }
    }
}

extension Vapor.BindAddress {
    init(from address: Apodini.BindAddress) {
        switch address {
        case let .hostname(host, port):
            self = .hostname(host, port: port)
        case .unixDomainSocket(let path):
            self = .unixDomainSocket(path: path)
        }
    }
}
