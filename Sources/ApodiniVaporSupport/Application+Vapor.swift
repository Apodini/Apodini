//
//  Application+Vapor.swift
//
//
//  Created by Tim Gymnich on 27.12.20.
//

import Apodini
import Vapor


extension Vapor.Application {
    struct LifecycleHandlery: Apodini.LifecycleHandler {
        var app: Vapor.Application

        func didBoot(_ application: Apodini.Application) throws {
            if let address = application.http.address {
                try app.server.start(address: Vapor.BindAddress(from: address))
            } else {
                try app.server.start()
            }
            try app.boot()
        }

        func shutdown(_ application: Apodini.Application) {
            app.server.shutdown()
            app.shutdown()
        }
    }

    convenience init(from app: Apodini.Application, environment env: Vapor.Environment = .production) {
        self.init(env, .shared(app.eventLoopGroup))
        app.lifecycle.use(LifecycleHandlery(app: self))

        // HTTP2
        self.http.server.configuration.supportVersions = Set(app.http.supportVersions.map { version in
            switch version {
            case .one: return Vapor.HTTPVersionMajor.one
            case .two: return Vapor.HTTPVersionMajor.two
            }
        })
        self.http.server.configuration.tlsConfiguration = app.http.tlsConfiguration
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
