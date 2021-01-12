//
//  Application+Vapor.swift
//  
//
//  Created by Tim Gymnich on 27.12.20.
//

@_implementationOnly import Vapor


extension Vapor.Application {
    struct LifecycleHandlery: Apodini.LifecycleHandler {
        var app: Vapor.Application

        func didBoot(_ application: Application) throws {
            try app.start()
        }

        func shutdown(_ application: Application) {
            app.shutdown()
        }
    }

    convenience init(from app: Apodini.Application, environment env: Vapor.Environment) {
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
        self.logger = app.logger
    }
}


extension Apodini.Application {
    var vapor: VaporApp {
        .init(application: self)
    }

    /// Holds the APNS Configuration
    struct VaporApp {
        struct ConfigurationKey: StorageKey {
            // swiftlint:disable nesting
            typealias Value = Vapor.Application
        }

        var app: Vapor.Application {
            if self.application.storage[ConfigurationKey.self] == nil {
                self.initialize()
            }
            // swiftlint:disable force_unwrapping
            return self.application.storage[ConfigurationKey.self]!
        }

        func initialize() {
            // swiftlint:disable force_try
            let env = try! Vapor.Environment.detect()
            self.application.storage[ConfigurationKey.self] = .init(from: application, environment: env)
        }

        private let application: Apodini.Application

        init(application: Apodini.Application) {
            self.application = application
        }
    }
}
