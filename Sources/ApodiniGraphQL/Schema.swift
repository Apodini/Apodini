//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import ApodiniUtils
import ApodiniExtension
import GraphQL


class GraphQLSchemaBuilder { // Can't call it GraphQLSchema bc that'd clash w/ the GraphQL package's equally-named type
    enum SchemaError: Swift.Error {
        case unableToConstructInputType(Any.Type)
        case unableToConstructOutputType(Any.Type)
        case noRootQueryFieldKeySpecified(AnyEndpoint)
        // Two or more handlers have defined the same key
        case duplicateRootQueryFieldKey(String)
    }
    
    
    // key: field name on the root query thing // TODO improve and move away from putting everyting into the root query!!!
    private var unaryHandlers: [String: GraphQLField] = [:]
    
    private var cachedGraphQLInputTypes: [ObjectIdentifier: GraphQLInputType] = [:]
    private var cachedGraphQLOutputTypes: [ObjectIdentifier: GraphQLOutputType] = [:]
    
    private(set) var finalizedSchema: GraphQLSchema?
    
    var isMutable: Bool { finalizedSchema == nil }
    
    init() {}
    
    
    private func assertSchemaMutable(_ caller: StaticString = #function) throws {
        precondition(isMutable, "Invalid operation '\(caller)': schema is already finalized")
    }
    
    
    func add<H: Handler>(_ endpoint: Endpoint<H>) throws {
        switch endpoint[CommunicationalPattern.self] {
        case .requestResponse:
            try addUnaryEndpoint(endpoint)
        case .serviceSideStream:
            // TODO addSubscriptionEndpoint
            fatalError("Not yet implemented")
        case .clientSideStream:
            // TODO model as a single function that expects an array as its parameter? (wouldn't really work bc these arguments would need to be all available when making the request, rather than sending them one after another...)
            fatalError("Not (yet?) supported")
        case .bidirectionalStream:
            // Same reason as the client-side streams: only the service-streaming half would make sense (via a subscription), but im not so sure about the client-streaming part...
            fatalError("Not (yet?) supported")
        }
    }
    
    
    private func addUnaryEndpoint<H: Handler>(_ endpoint: Endpoint<H>) throws {
        try assertSchemaMutable()
        guard let tmp_rootQueryFieldName = endpoint[Context.self].get(valueFor: TMP_GraphQLRootQueryFieldName.self) else {
            throw SchemaError.noRootQueryFieldKeySpecified(endpoint)
        }
        guard !unaryHandlers.keys.contains(tmp_rootQueryFieldName) else {
            throw SchemaError.duplicateRootQueryFieldKey(tmp_rootQueryFieldName)
        }
        unaryHandlers[tmp_rootQueryFieldName] = GraphQLField(
            type: try toGraphQLOutputType(H.Response.Content.self),
            description: "todo",
            deprecationReason: nil,
            args: try mapEndpointParametersToFieldArgs(endpoint),
            resolve: { source, args, context, eventLoopGroup, info in
                // TODO do some of these need to be lifted out of the closure?
                let defaults = endpoint[DefaultValueStore.self]
                let delegateFactory = endpoint[DelegateFactory<H, GraphQLInterfaceExporter>.self]
                let delegate = delegateFactory.instance()
                let decodingStrategy = GraphQLEndpointDecodingStrategy().applied(to: endpoint).typeErased
                let responseFuture: EventLoopFuture<Apodini.Response<H.Response.Content>> = decodingStrategy
                    .decodeRequest(from: args, with: DefaultRequestBasis(), with: eventLoopGroup.next()) // TODO request basis!!!
                    .insertDefaults(with: defaults)
                    .cache()
                    .evaluate(on: delegate)
                return responseFuture // TODO does this need to be wrapped in some kind of dedicated data structure?
                    .map { $0.content }
                    .inspect { print("result for \(tmp_rootQueryFieldName): \($0)") }
                    .map { $0 }
                
            },
            subscribe: nil
        )
    }
    
    
    
    private func toGraphQLInputType(_ type: Any.Type) throws -> GraphQLInputType {
        if let cached = cachedGraphQLInputTypes[type] {
            return cached
        }
        func cacheResult(_ graphqlType: GraphQLInputType) -> GraphQLInputType {
            cachedGraphQLInputTypes[type] = graphqlType
            return graphqlType
        }
        if let graphqlType = _toGraphQLType(type) as? GraphQLInputType {
            return cacheResult(graphqlType)
        } else {
            throw SchemaError.unableToConstructInputType(type)
        }
    }
    
    private func toGraphQLOutputType(_ type: Any.Type) throws -> GraphQLOutputType {
        if let cached = cachedGraphQLOutputTypes[type] {
            return cached
        }
        func cacheResult(_ graphqlType: GraphQLOutputType) -> GraphQLOutputType {
            cachedGraphQLOutputTypes[type] = graphqlType
            return graphqlType
        }
        if let graphqlType = _toGraphQLType(type) as? GraphQLOutputType {
            return cacheResult(graphqlType)
        } else {
            throw SchemaError.unableToConstructOutputType(type)
        }
    }
    
    
    private func _toGraphQLType(_ type: Any.Type) -> GraphQLType? {
        if type == String.self {
            return GraphQLString
        } else if type == Int.self || type == Int32.self {
            return GraphQLInt
        } else if type == Float.self || type == Double.self {
            return GraphQLFloat
        } else if type == Bool.self {
            return GraphQLBoolean
        } else if type == UUID.self {
            // Can we safely map this to the GraphQLID type?
            fatalError("TODO")
        } else {
            return nil
        }
    }
    
    
    private func mapEndpointParametersToFieldArgs<H>(_ endpoint: Endpoint<H>) throws -> GraphQLArgumentConfigMap {
        guard !endpoint.parameters.isEmpty else {
            return [:]
        }
        var argsMap: GraphQLArgumentConfigMap = [:]
        for parameter in endpoint.parameters {
            argsMap[parameter.name] = GraphQLArgument(
                type: try toGraphQLInputType(parameter.originalPropertyType),
                description: "todo?",
                defaultValue: nil // TODO?
            )
        }
        return argsMap
    }
    
    
    
    @discardableResult
    func finalize() throws -> GraphQLSchema {
        if let finalizedSchema = finalizedSchema {
            return finalizedSchema
        }
        self.finalizedSchema = try GraphQLSchema(
            query: GraphQLObjectType(
                name: "RootQueryType",
                description: "_todo_",
                fields: self.unaryHandlers // TODO better mapping here!
                //interfaces: <#T##[GraphQLInterfaceType]#>,
                //isTypeOf: <#T##GraphQLIsTypeOf?##GraphQLIsTypeOf?##(_ source: Any, _ eventLoopGroup: EventLoopGroup, _ info: GraphQLResolveInfo) throws -> Bool#>
            )
            //mutation: <#T##GraphQLObjectType?#>,
            //subscription: <#T##GraphQLObjectType?#>,
            //types: <#T##[GraphQLNamedType]#>,
            //directives: <#T##[GraphQLDirective]#>
        )
        return finalizedSchema!
    }
}
