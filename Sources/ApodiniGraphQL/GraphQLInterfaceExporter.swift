//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Apodini
import ApodiniExtension
import ApodiniNetworking
import Logging
import Foundation


public class GraphQLConfig: Configuration { // Not called GraphQL bc that'd clash w/ the module name TODO call it GraphQL anyway
    fileprivate let graphqlEndpoint: [HTTPPathComponent]
    fileprivate let enableGraphiQL: Bool
    
    public init(graphqlEndpoint: [HTTPPathComponent] = "/graphql", enableGraphiQL: Bool) {
        precondition(graphqlEndpoint.allSatisfy(\.isConstant), "GraphQL endpoint must be a constant path")
        self.graphqlEndpoint = graphqlEndpoint
        self.enableGraphiQL = enableGraphiQL
    }
    
    public func configure(_ app: Application) {
        let exporter = GraphQLInterfaceExporter(app: app, config: self)
        app.registerExporter(exporter: exporter)
    }
}


class GraphQLInterfaceExporter: InterfaceExporter {
    private let app: Application
    private let config: GraphQLConfig
    private let logger: Logger
    private let server: GraphQLServer
    
    init(app: Application, config: GraphQLConfig) {
        self.app = app
        self.config = config
        self.logger = Logger(label: "\(app.logger.label).GraphQL")
        self.server = GraphQLServer()
    }
    
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        // TODO
    }
    
    
    func export<H: Handler>(blob endpoint: Endpoint<H>) where H.Response.Content == Blob {
        logger.error("Blob endpoint \(endpoint) cannot be exported")
    }
    
    
    func finishedExporting(_ webService: WebServiceModel) {
        app.httpServer.registerRoute(.GET, config.graphqlEndpoint, responder: GraphQLQueryHTTPResponder(server: server))
        app.httpServer.registerRoute(.POST, config.graphqlEndpoint, responder: GraphQLQueryHTTPResponder(server: server))
        if config.enableGraphiQL {
            registerGraphiQLEndpoint()
        }
    }
    
    private func registerGraphiQLEndpoint() {
        app.httpServer.registerRoute(.GET, "/graphiql") { req -> HTTPResponse in
            guard let url = Bundle.module.url(forResource: "graphiql", withExtension: "html") else {
                throw HTTPAbortError(status: .internalServerError)
            }
            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                throw HTTPAbortError(status: .internalServerError)
            }
            return HTTPResponse(
                version: req.version,
                status: .ok,
                headers: HTTPHeaders {
                    $0[.contentType] = .html
                },
                bodyStorage: .buffer(.init(data: data))
            )
        }
    }
}
