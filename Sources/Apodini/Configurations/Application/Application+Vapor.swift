//
//  Application+Vapor.swift
//  
//
//  Created by Tim Gymnich on 27.12.20.
//

@_implementationOnly import Vapor


extension Vapor.Application {
    struct LifecycleHandler: Apodini.LifecycleHandler {
        var app: Vapor.Application

        func didBoot(_ application: Application) throws {
            try app.run()
        }

        func shutdown(_ application: Application) {
            app.shutdown()
        }
    }

    convenience init(from app: Apodini.Application) {
        self.init(.production, .shared(app.eventLoopGroup))
        app.lifecycle.use(LifecycleHandler(app: self))
        // APNS
        self.apns.configuration = app.apns.configuration
        // Databases
        for id in app.databases.ids() {
            if let config = app.databases.configuration(for: id) {
                self.databases.use(config, as: id)
            }
        }
        // HTTP2
        self.http.server.configuration.supportVersions = Set(app.http.supportVersions.map { version in
            switch version {
            case .one: return Vapor.HTTPVersionMajor.one
            case .two: return Vapor.HTTPVersionMajor.one
            }
        })
        self.http.server.configuration.tlsConfiguration = app.http.tlsConfiguration
        self.logger = app.logger
    }
}
