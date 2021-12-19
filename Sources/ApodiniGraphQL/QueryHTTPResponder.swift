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
    
    
    func respond(to httpRequest: HTTPRequest) -> HTTPResponseConvertible /*EventLoopFuture<HTTPResponse>*/ {
        let graphQLRequest: GraphQLRequest
        switch httpRequest.method {
        case .GET:
            graphQLRequest = GraphQLRequest(
                query: try! httpRequest.getQueryParam(for: "query", as: String.self)!,
                variables: (try! httpRequest.getQueryParam(for: "variables", as: [String: Map].self)) ?? [:],
                operationName: try! httpRequest.getQueryParam(for: "operationName", as: String.self)
            )
        case .POST:
            switch httpRequest.headers[.contentType]! {
            case .json, .json(charset: nil): // TODO do we have to explicitly support all of these here? or would it make more sense to define the pattern matching/equality checks in a way that it only considers the type and subtype, but ignores stuff like the charset?
                graphQLRequest = try! httpRequest.bodyStorage.getFullBodyData(decodedAs: GraphQLRequest.self, using: JSONDecoder())
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
                fatalError("Unexpected Content-Type: \(httpRequest.headers[.contentType] as Any)")
            }
        default:
            fatalError("Unexpected HTTP method: \(httpRequest.method)")
        }
        let schema = server.schemaBuilder.finalizedSchema!
        
        let graphqlResult: EventLoopFuture<GraphQLResult>
        do {
            graphqlResult = try graphql(
                schema: schema,
                request: graphQLRequest.query,
                eventLoopGroup: httpRequest.eventLoop,
                variableValues: graphQLRequest.variables
            )
        } catch let error as GraphQLError {
            graphqlResult = httpRequest.eventLoop.makeSucceededFuture(GraphQLResult(data: nil, errors: [error]))
        } catch {
            return HTTPResponse(
                version: httpRequest.version,
                status: .internalServerError,
                headers: HTTPHeaders {
                    $0[.contentType] = .text(.plain)
                },
                bodyStorage: .buffer(initialValue: "\(error)") // TODO don't do this. no need to leak the error
            )
        }
        
        return graphqlResult.map { (result: GraphQLResult) -> HTTPResponse in
            let httpResponse = HTTPResponse(
                version: httpRequest.version,
                status: .ok,
                headers: HTTPHeaders {
                    $0[.contentType] = .json
                }
            )
            try! httpResponse.bodyStorage.write(encoding: result, using: JSONEncoder())
            return httpResponse
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
