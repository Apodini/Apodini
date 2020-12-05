//
//  WebService.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Vapor
<<<<<<< HEAD
import ArgumentParser
import NIOSSL

=======
import Fluent
import FluentMongoDriver
>>>>>>> server-configuration

/// Each Apodini program conists of a `WebService`component that is used to describe the Web API of the Web Service
public protocol WebService: Component, ConfigurationCollection {
    /// The currennt version of the `WebService`
    var version: Version { get }
    
    /// An empty initializer used to create an Apodini `WebService`
    init()
}


extension WebService {
    /// This function is exectured to start up an Apodini `WebService`
    public static func main() {
        Command<Self>.main()
    }
    
    
    /// The current version of the `WebService`
    public var version: Version {
        Version()
    }
    
    
    /// An empty initializer used to create an Apodini `WebService`
    public init() {
        self.init()
    }
}


extension WebService {
    func register(_ semanticModelBuilders: SemanticModelBuilder...) {
        let visitor = SynaxTreeVisitor(semanticModelBuilders: semanticModelBuilders)
        self.visit(visitor)
    }
    
    private func visit(_ visitor: SynaxTreeVisitor) {
        visitor.addContext(APIVersionContextKey.self, value: version, scope: .environment)
        visitor.addContext(PathComponentContextKey.self, value: [version], scope: .environment)
        Group {
            content
        }.visit(visitor)
    }
}


private struct Command<W: WebService>: ParsableCommand {
    /// ArguementParser currently supports the following options:
    ///     --cert  File-path to a .pem file for the certificate to use
    ///     --key   File-path ot a .pem file for the key to use
    ///
    /// Only if both --cert and --key are set, HTTP/1 & HTTP/2 and TLS will be enabled. Otherwise, only HTTP/1 will be enabled, without TLS.
    @ArgumentParser.Option(help: "Path to a certificate .pem file")
    var cert: String?
    @ArgumentParser.Option(help: "Path to a key .pem file")
    var key: String?


    private func configureHttp2(for app: Application) throws {
        if let cert = cert, let key = key {
            let certFile = try Data(contentsOf: URL(fileURLWithPath: cert))
            let keyFile = try Data(contentsOf: URL(fileURLWithPath: key))
            let certificates = try NIOSSLCertificate.fromPEMBytes([UInt8](certFile))
            let privateKey = try NIOSSLPrivateKey.init(bytes: [UInt8](keyFile), format: .pem)
            app.http.server.configuration.supportVersions = [.one, .two]
            app.http.server.configuration.tlsConfiguration = .forServer(certificateChain: certificates.map { .certificate($0) }, privateKey: .privateKey(privateKey))
        }
    }

    func run() throws {
        do {
            let environmentName = try Environment.detect().name
            var env = Environment(name: environmentName, arguments: ["vapor"])
            try LoggingSystem.bootstrap(from: &env)
            let app = Application(env)

            let webService = W()
            try configureHttp2(for: app)

            webService.register(
                RESTSemanticModelBuilder(app),
                GraphQLSemanticModelBuilder(app),
                GRPCSemanticModelBuilder(app),
                WebSocketSemanticModelBuilder(app)
            )

            webService.configuration.configure(app)

            defer {
                app.shutdown()
            }
            try app.run()
        } catch {
            print(error)
        }
    }
}
