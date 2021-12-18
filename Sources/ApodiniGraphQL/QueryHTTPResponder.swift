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
                variables: (try! httpRequest.getQueryParam(for: "variables", as: [String: String].self)) ?? [:],
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
////        print(graphQLRequest)
//        let schema = try! GraphQLSchema(
//            query: GraphQLObjectType(
//                name: "RootQuery",
//                description: "root querY desc",
//                fields: [
//                    "hello": GraphQLField(
//                        type: GraphQLString,//<#T##GraphQLOutputType#>,
//                        description: "field desc",
//                        deprecationReason: nil,
//                        args: [:], // TODO
//                        resolve: { (
//                            source: Any, _ args: Map, context: Any,
//                            eventLoopGroup: EventLoopGroup, info: GraphQLResolveInfo
//                        ) throws -> EventLoopFuture<Any?> in
//                            // TODO
//                            print("source", source)
//                            print("args", args)
//                            print("context", context)
//                            print("eventLoopGroup", eventLoopGroup)
//                            print("info", info)
//                            //fatalError()
//                            return eventLoopGroup.next().makeSucceededFuture(["hello", "world", 123])
//                        },
//                        subscribe: nil //<#T##GraphQLFieldResolve?#>
//                    ),
//                    "greet": GraphQLField(
//                        type: GraphQLString,
//                        description: "Greet. what else should it be?",
//                        deprecationReason: "oh no",
//                        args: ["name": GraphQLArgument(type: GraphQLString, description: "YouR name", defaultValue: nil)],
//                        resolve: { (
//                            source: Any, _ args: Map, context: Any,
//                            eventLoopGroup: EventLoopGroup, info: GraphQLResolveInfo
//                        ) throws -> EventLoopFuture<Any?> in
//                            print("source", source)
//                            print("args", args)
//                            print("context", context)
//                            print("eventLoopGroup", eventLoopGroup)
//                            print("info", info)
//                            let name = try args.dictionaryValue()["name"]!.string!
//                            return eventLoopGroup.next().makeSucceededFuture("Hello, \(name)!")
//                        }),
//                    "formPerson": GraphQLField(
//                        type: GraphQLObjectType(
//                            name: "Person",
//                            fields: [
//                                "name": GraphQLField(type: GraphQLString),
//                                //"randomNumber": GraphQLField(type: GraphQLInt)
//                                "randomNumber": GraphQLField(
//                                    type: GraphQLString,
//                                    resolve: { source, args, context, info in
//                                        print("\n\n=====randomNumber")
//                                        print("source: \(source)")
//                                        print("args: \(args)")
//                                        print("context: \(context)")
//                                        print("info: \(info)")
//                                        return nil
//                                    }
//                                )
//                            ]
//                        ),
//                        //description: <#T##String?#>,
//                        //deprecationReason: <#T##String?#>,
//                        args: ["name": GraphQLArgument(type: GraphQLString, description: nil, defaultValue: nil)],
//                        resolve: { source, args, context, info in
//                            print("source", source)
//                            print("args", args)
//                            print("context", context)
//                            print("info", info)
//                            //fatalError()
//                            struct Person: Codable {
//                                let name: String
//                                let randomNumber: Int
//                                init(name: String, randomNumber: Int = Int.random(in: Int.min...Int.max)) {
//                                    self.name = name
//                                    self.randomNumber = randomNumber
//                                }
//                            }
//                            return Person(name: try args.dictionaryValue()["name"]!.string!)
//                        }
//                    )
//                ],
//                interfaces: [], //<#T##[GraphQLInterfaceType]#>,
//                isTypeOf: nil//<#T##GraphQLIsTypeOf?##GraphQLIsTypeOf?##(_ source: Any, _ eventLoopGroup: EventLoopGroup, _ info: GraphQLResolveInfo) throws -> Bool#>
//            ),
//            mutation: nil,
//            subscription: nil,
//            types: [], //<#T##[GraphQLNamedType]#>,
//            directives: [] //<#T##[GraphQLDirective]#>
//        )
        let schema = server.schemaBuilder.finalizedSchema!
        
        let graphqlResult: EventLoopFuture<GraphQLResult>
        do {
            graphqlResult = try graphql(
                schema: schema,
                request: graphQLRequest.query,
                eventLoopGroup: httpRequest.eventLoop
            )
        } catch let error as GraphQLError {
//            print(type(of: error))
//            print(error)
//            fatalError()
            graphqlResult = httpRequest.eventLoop.makeSucceededFuture(GraphQLResult(data: nil, errors: [error]))
        } catch {
            return HTTPResponse(
                version: httpRequest.version,
                status: .internalServerError,
                headers: HTTPHeaders {
                    // TODO?
                    $0[.contentType] = .text(.plain)
                },
                bodyStorage: .buffer(initialValue: "\(error)") // TODO don't do this. no need to leak the error
            )
        }
//        print(graphqlResult)
        
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
            //return HTTPResponse(version: httpRequest.version, status: .internalServerError, headers: HTTPHeaders())
            //return HTTPAbortError(status: .notImplemented)
        }
        
//        fatalError("")
    }
}


struct GraphQLRequest: Codable {
    enum CodingKeys: String, CodingKey {
        case query, variables, operationName
    }
    let query: String
    let variables: [String: String]
    let operationName: String?
    
    init(query: String, variables: [String: String] = [:], operationName: String? = nil) {
        self.query = query
        self.variables = variables
        self.operationName = operationName
    }
    
    init(from decoder: Decoder) throws {
        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        self.query = try keyedContainer.decode(String.self, forKey: .query)
        self.variables = try keyedContainer.decodeIfPresent([String: String].self, forKey: .variables) ?? [:]
        self.operationName = try keyedContainer.decodeIfPresent(String.self, forKey: .operationName)
    }
}

