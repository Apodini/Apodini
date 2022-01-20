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


public class GraphQL: Configuration {
    fileprivate let graphQLEndpoint: [HTTPPathComponent]
    fileprivate let enableGraphiQL: Bool
    fileprivate let graphiQLEndpoint: [HTTPPathComponent]
    
    public init(
        graphQLEndpoint: [HTTPPathComponent] = "/graphql",
        enableGraphiQL: Bool = false,
        graphiQLEndpoint: [HTTPPathComponent] = "/graphiql"
    ) {
        precondition(graphQLEndpoint.allSatisfy(\.isConstant), "GraphQL endpoint must be a constant path")
        precondition(graphiQLEndpoint.allSatisfy(\.isConstant), "GraphiQL endpoint must be a constant path")
        self.graphQLEndpoint = graphQLEndpoint
        self.enableGraphiQL = enableGraphiQL
        self.graphiQLEndpoint = graphiQLEndpoint
    }
    
    public func configure(_ app: Application) {
        let exporter = GraphQLInterfaceExporter(app: app, config: self)
        app.registerExporter(exporter: exporter)
    }
}


class GraphQLInterfaceExporter: InterfaceExporter {
    private let app: Application
    private let config: GraphQL
    private let logger: Logger
    private let schemaBuilder: GraphQLSchemaBuilder
    
    init(app: Application, config: GraphQL) {
        self.app = app
        self.config = config
        self.logger = Logger(label: "\(app.logger.label).GraphQL")
        self.schemaBuilder = GraphQLSchemaBuilder()
    }
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        do {
            try schemaBuilder.add(endpoint)
            logger.notice("Exported endpoint \(endpoint)")
        } catch let error as GraphQLSchemaBuilder.SchemaError {
            switch error {
            case let .unsupportedOpCommPatternTuple(operation, commPattern):
                logger.error("Not exporting endpoint: unsupported operation/commPattern tuple (\(operation), \(commPattern)). (endpoint: \(endpoint))")
            default:
                fatalError("\(error)")
            }
        } catch {
            fatalError("\(error)")
        }
    }
    
    func export<H: Handler>(blob endpoint: Endpoint<H>) where H.Response.Content == Blob {
        logger.error("Blob endpoint \(endpoint) cannot be exported")
    }
    
    func finishedExporting(_ webService: WebServiceModel) {
        let schema: GraphQLSchema
        do {
            schema = try schemaBuilder.finalize()
        } catch {
            fatalError("Error finalizing GraphQL schema: \(error)")
        }
        app.httpServer.registerRoute(.GET, config.graphQLEndpoint, responder: GraphQLQueryHTTPResponder(schema: schema))
        app.httpServer.registerRoute(.POST, config.graphQLEndpoint, responder: GraphQLQueryHTTPResponder(schema: schema))
        if config.enableGraphiQL {
            registerGraphiQLEndpoint()
        }
    }
    
    private func registerGraphiQLEndpoint() {
        let graphqlEndpointUrl = app.httpConfiguration.uriPrefix + config.graphQLEndpoint.httpPathString
        app.httpServer.registerRoute(.GET, config.graphiQLEndpoint) { req -> HTTPResponse in
            guard let url = Bundle.module.url(forResource: "graphiql", withExtension: "html") else {
                throw HTTPAbortError(status: .internalServerError)
            }
            guard var htmlPage = (try? Data(contentsOf: url)).flatMap({ String(data: $0, encoding: .utf8) }) else {
                throw HTTPAbortError(status: .internalServerError)
            }
            htmlPage = htmlPage.replacingOccurrences(of: "{{APODINI_GRAPHQL_ENDPOINT_URL}}", with: graphqlEndpointUrl)
            return HTTPResponse(
                version: req.version,
                status: .ok,
                headers: HTTPHeaders {
                    $0[.contentType] = .html
                },
                bodyStorage: .buffer(.init(string: htmlPage))
            )
        }
    }
}


struct GraphQLEndpointDecodingStrategy: EndpointDecodingStrategy {
    typealias Input = Map
    
    func strategy<Element: Codable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Input> {
        GraphQLEndpointParameterDecodingStrategy<Element>(name: parameter.name).typeErased
    }
}


private struct GraphQLEndpointParameterDecodingStrategy<T: Codable>: ParameterDecodingStrategy {
    typealias Element = T
    typealias Input = Map
    
    private struct Wrapped<T: Codable>: Codable {
        let value: T
    }
    
    let name: String
    
    func decode(from input: Input) throws -> T {
        guard let value = try input.dictionaryValue(converting: true)[name] else {
            throw ApodiniError(type: .badInput, reason: "Unable to find parameter named '\(name)' (T: \(T.self))")
        }
        if value.isUndefined {
            throw ApodiniError(type: .badInput, reason: "Parameter value is `undefined`")
        }
        // We need to wrap this in a dictionary to make sure that we're working with a top-level object.
        // (This isn't strictly necessary, since these coding steps seem to be working fine for top-level strings,
        // but it reduces the probability of something going wrong, because otherwuise we'd be emitting not-standard-conformant JSON)
        let data = try JSONEncoder().encode(Map.dictionary(["value": value]))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(GraphQLSchemaBuilder.dateFormatter)
        return try decoder.decode(Wrapped<T>.self, from: data).value
    }
}
