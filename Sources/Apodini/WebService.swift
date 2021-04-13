//
//  WebService.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Foundation
import Logging
import ApodiniUtils


/// Each Apodini program consists of a `WebService`component that is used to describe the Web API of the Web Service
public protocol WebService: Component, ConfigurationCollection {
    /// The current version of the `WebService`
    var version: Version { get }
    
    /// An empty initializer used to create an Apodini `WebService`
    init()
}


extension WebService {
    /// This function is executed to start up an Apodini `WebService`
    public static func main() throws {
        try main(waitForCompletion: true)
    }

    
    /// This function is executed to start up an Apodini `WebService`
    @discardableResult
    static func main(waitForCompletion: Bool) throws -> Application {
        let app = Application()
        LoggingSystem.bootstrap(StreamLogHandler.standardError)

        main(app: app)
        
        guard waitForCompletion else {
            try app.boot()
            return app
        }

        defer {
            app.shutdown()
        }

        try app.run()
        return app
    }
    

    /// This function is provided to start up an Apodini `WebService`. The `app` parameter can be injected for testing purposes only. Use `WebService.main()` to startup an Apodini `WebService`.
    /// - Parameter app: The app instance that should be injected in the Apodini `WebService`
    static func main(app: Application) {
        let webService = Self()
        webService.configuration.configure(app)
        
        // If no specific address hostname is provided we bind to the default address to automatically and correcly bind in Docker containers.
        if app.http.address == nil {
            let defaults = HTTPConfiguration.Defaults.self
            app.http.address = .hostname(defaults.hostname, port: defaults.port)
        }
        
        #if DEBUG // fails DownloadsTests of TestWebService, therefore skipped
        if !webService.isTest, case let .hostname(_, httpPort) = app.http.address, let port = httpPort {
            runShellCommand(.killPort(port))
        }
        #endif
        
        webService.register(
            app.exporters.semanticModelBuilderBuilder(SemanticModelBuilder(app))
        )
    }
    
    
    /// The current version of the `WebService`
    public var version: Version {
        Version()
    }
}


extension WebService {
    func register(_ modelBuilder: SemanticModelBuilder) {
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        self.visit(visitor)
        visitor.finishParsing()
    }
    
    private func visit(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(APIVersionContextKey.self, value: version, scope: .environment)
        visitor.addContext(PathComponentContextKey.self, value: [version], scope: .environment)
        Group {
            content
        }.accept(visitor)
    }
}

#if DEBUG
fileprivate extension WebService {
    var isTest: Bool {
        String(describing: Self.self) == "TestWebService"
    }
}
#endif
