//
//  GraphQLSemanticModelBuilder.swift
//
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Fluent
@_implementationOnly import Vapor
import GraphQL
import NIO


enum NetworkError: Error {
    case unauthorised
    case timeout
    case serverError
    case invalidResponse
    case noBody
}

class GraphQLSemanticModelBuilder: SemanticModelBuilder {
    var schema = try! GraphQLSchema(
            query: GraphQLObjectType(
                    name: "Apodini",
                    fields: [
                        "test": GraphQLField(
                                type: GraphQLString,
                                resolve: { _, _, _, _ in
                                    "It is working!"
                                }
                        )
                    ]
            )
    )
    var fields = [String: GraphQLField]()

//    private let answer = Answer()
    private func graphql_server(_ req: Vapor.Request) throws -> EventLoopFuture<String> {
        guard let body = req.body.string else {
            throw NetworkError.noBody
        }

        // Create Swift dict
        var query = "{}"
        let data = body.data(using: .utf8)!
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                if let q = jsonArray["query"] as? String {
                    query = q
                } else {
                    print("jsonArray doesn't have query parameter")
                }

            } else {
                print("bad json")
                throw NetworkError.noBody
            }
        } catch let error as NSError {
            print(error)
            throw NetworkError.noBody
        }

        print("The query is", query)
        return try graphql(schema: schema,
                request: query,
                eventLoopGroup: req.eventLoop).map { result -> String in
            result.description
        }

    }

    override init(_ app: Application) {
        // Start  the server
        super.init(app)
        // For Query
        app.post("graphql", use: graphql_server)
        // TODO: app.get("graphql") -> For graphql interface
    }


    override func register<H: Handler>(handler: H, withContext context: Context) {
        super.register(handler: handler, withContext: context)

        let guards = context.get(valueFor: GuardContextKey.self)
        let pathArray = context.get(valueFor: PathComponentContextKey.self)
        let responseTransformerTypes = context.get(valueFor: ResponseContextKey.self)
        print(pathArray)
        // TODO: Instead of taking just  one value from the path array. Use the whole array to build the query structure
        // TODO: How to put handle function to the resolve. How do we utilize _,_,_,_ part?
        if (pathArray.count > 1) {
            fields[pathArray[1] as! String] = GraphQLField(type: GraphQLString, resolve: { source, args, context, info in
                print(source)
                print(args)
                print(context)
                print(info)
                print("------")
                return handler.handle() as! String // TODO: Instead of string try encodable
            })
        }

    }

    override func finishedRegistration() {
        self.schema = try! GraphQLSchema(
                query: GraphQLObjectType(
                        name: "Apodini",
                        fields: fields
                )
        )
        print("GraphQL schema creation is done!")
    }

}
