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
import GraphQL


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
        let commPattern = endpoint[CommunicationalPattern.self]
        guard commPattern == .requestResponse else {
            logger.warning("Endpoint defines currently-unsupported communicational pattern \(commPattern). Ignoring. (Endpoint: \(endpoint)).")
            return
        }
        guard endpoint[Context.self].get(valueFor: TMP_GraphQLRootQueryFieldName.self) != nil else {
            logger.warning("Unary endpoint does not define GraphQL root query type field name. Skipping. (Endpoint: \(endpoint)).")
            return
        }
        try! server.schemaBuilder.add(endpoint)
    }
    
    
    func export<H: Handler>(blob endpoint: Endpoint<H>) where H.Response.Content == Blob {
        logger.error("Blob endpoint \(endpoint) cannot be exported")
    }
    
    
    func finishedExporting(_ webService: WebServiceModel) {
        try! server.schemaBuilder.finalize()
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


struct GraphQLEndpointDecodingStrategy: EndpointDecodingStrategy {
    typealias Input = GraphQL.Map
    
    func strategy<Element: Codable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Input> {
        GraphQLEndpointParameterDecodingStrategy<Element>(name: parameter.name).typeErased
    }
}


private struct GraphQLEndpointParameterDecodingStrategy<T: Codable>: ParameterDecodingStrategy {
    typealias Element = T
    typealias Input = GraphQL.Map
    
    struct Error: Swift.Error {
        let message: String
    }
    
    let name: String
    
    func decode(from input: Input) throws -> T {
        guard let value = try input.dictionaryValue(converting: false /*TODO true?*/)[name] else {
            throw Error(message: "Unable to find parameter named '\(name)' (T: \(T.self))")
        }
        // TODO now we need to somehow "decode" the expected type from the parameter...
        print(value)
        // This will only work for objects, but not for fields that are like direct ints or strings...
        let data = try JSONEncoder().encode(value)
        let retval = try JSONDecoder().decode(T.self, from: data)
        print("retval for \(name) (raw: \(value)): \(retval)")
        return retval
    }
}
