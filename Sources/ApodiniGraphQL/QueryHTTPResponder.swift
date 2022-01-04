//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ApodiniNetworking
import ApodiniUtils
import NIO
import GraphQL


extension HTTPMediaType {
    static let graphQL = HTTPMediaType(type: "application", subtype: "graphql")
}


class GraphQLQueryHTTPResponder: HTTPResponder {
    private let server: GraphQLServer
    
    init(server: GraphQLServer) {
        self.server = server
    }
    
    
    func respond(to httpRequest: HTTPRequest) -> HTTPResponseConvertible {
        let resultFuture: EventLoopFuture<GraphQLResult>
        do {
            resultFuture = try handleRequest(httpRequest)
        } catch let error as GraphQLError {
            resultFuture = httpRequest.eventLoop.makeSucceededFuture(GraphQLResult(data: nil, errors: [error]))
        } catch {
            resultFuture = httpRequest.eventLoop.makeSucceededFuture(GraphQLResult(data: nil, errors: [GraphQLError(error)]))
        }
        return resultFuture
            .hop(to: httpRequest.eventLoop)
            .map { (result: GraphQLResult) -> HTTPResponse in
                let httpResponse = HTTPResponse(
                    version: httpRequest.version,
                    status: .ok,
                    headers: HTTPHeaders {
                        $0[.contentType] = .json
                    }
                )
                do {
                    try httpResponse.bodyStorage.write(encoding: result, using: JSONEncoder())
                } catch {
                    httpResponse.bodyStorage.write(#"{"errors": [{"message": "Error encoding response", "path": []}]}"#)
                }
                return httpResponse
            }
    }
    
    
    private func handleRequest(_ httpRequest: HTTPRequest) throws -> EventLoopFuture<GraphQLResult> {
        func wrappingError<T>(_ block: @autoclosure () throws -> T, errorPrefix: @autoclosure () -> String) rethrows -> T {
            do {
                return try block()
            } catch {
                throw GraphQLError(
                    message: "\(errorPrefix()): \(error.localizedDescription)",
                    originalError: error
                )
            }
        }
        let graphQLRequest: GraphQLRequest
        
        switch httpRequest.method {
        case .GET:
            guard let query = try wrappingError(try httpRequest.getQueryParam(for: "query", as: String.self), errorPrefix: "Error decoding query") else {
                throw GraphQLError(message: "missing query")
            }
            let variables = try wrappingError(
                try httpRequest.getQueryParam(for: "variables", as: [String: Map].self),
                errorPrefix: "Error decoding variables"
            ) ?? [:]
            let operationName = try wrappingError(
                try httpRequest.getQueryParam(for: "operationName", as: String.self),
                errorPrefix: "Error decoding operationName"
            )
            graphQLRequest = GraphQLRequest(query: query, variables: variables, operationName: operationName)
        case .POST:
            switch httpRequest.headers[.contentType]! {
            case .json, .json(charset: nil): // TODO do we have to explicitly support all of these here? or would it make more sense to define the pattern matching/equality checks in a way that it only considers the type and subtype, but ignores stuff like the charset?
                graphQLRequest = try wrappingError(
                    try httpRequest.bodyStorage.getFullBodyData(decodedAs: GraphQLRequest.self, using: JSONDecoder()),
                    errorPrefix: "Error decoding request body"
                    )
            case .graphQL:
                // According to https://graphql.org/learn/serving-over-http/ , in this case the body contains the query string
                // TODO where do we get the other things from?
                // have a look at the url query params anyway?
                graphQLRequest = GraphQLRequest(
                    query: httpRequest.bodyStorage.getFullBodyDataAsString()!,
                    variables: [:],
                    operationName: nil
                )
            default:
                throw GraphQLError(message: "Unexpected Content-Type: \(httpRequest.headers[.contentType] as Any)")
            }
        default:
            throw GraphQLError(message: "Unexpected HTTP method: \(httpRequest.method)")
        }
        guard let schema = server.schemaBuilder.finalizedSchema else {
            throw GraphQLError(message: "Internal Error: Unable to access finalised schema.")
        }
        do {
            return try graphql(
                schema: schema,
                request: graphQLRequest.query,
                eventLoopGroup: httpRequest.eventLoop,
                variableValues: graphQLRequest.variables
            )
        } catch let error as GraphQLError {
            throw error
        } catch {
            // We caught an error while evaluating the request, but it is not a GraphQLError.
            // This usually means that something else (e.g. somewhere in Apodini) failed.
            // TODO do we really want to just leak this error?
            throw error
        }
    }
}


struct GraphQLRequest: Codable {
    enum CodingKeys: String, CodingKey {
        case query, variables, operationName
    }
    let query: String
    let variables: [String: Map]
    let operationName: String?
    
    init(query: String, variables: [String: Map] = [:], operationName: String? = nil) {
        self.query = query
        self.variables = variables
        self.operationName = operationName
    }
    
    init(from decoder: Decoder) throws {
        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        self.query = try keyedContainer.decode(String.self, forKey: .query)
        self.variables = try keyedContainer.decodeIfPresent([String: Map].self, forKey: .variables) ?? [:]
        self.operationName = try keyedContainer.decodeIfPresent(String.self, forKey: .operationName)
    }
}
