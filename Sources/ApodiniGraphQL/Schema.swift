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
import ApodiniTypeInformation


extension TypeInformation {
    func isEqual(to type: Any.Type) -> Bool {
        try! self == .init(type: type)
    }
}


class GraphQLSchemaBuilder { // Can't call it GraphQLSchema bc that'd clash w/ the GraphQL package's equally-named type
    enum SchemaError: Swift.Error {
        case unableToConstructInputType(TypeInformation, underlying: Swift.Error?)
        case unableToConstructOutputType(TypeInformation, underlying: Swift.Error)
        case noRootQueryFieldKeySpecified(AnyEndpoint)
        // Two or more handlers have defined the same key
        case duplicateRootQueryFieldKey(String)
        
        case unsupportedOpCommPatternTuple(Apodini.Operation, CommunicationalPattern)
        // Somewhere while handling a type, the schema encountered a `Swift.Never` type (which can't be represented in GraphQL)
        // ^^ TODO can we somehow represent these anyway?
        case unexpectedNeverType
        
        case other(String)
    }
    
    
    private enum GraphQLTypeUsageContext { // TODO drop the GraphQL prefix
        case input, output, fieldInObject // TODO is the last one here still needed?
    }
    
    
    private struct TypesCacheEntry {
        let input: GraphQLInputType?
        let output: GraphQLOutputType
        
//        private init(input: GraphQLInputType?, output: GraphQLOutputType) {
//            self.input = input
//            self.output = output
//        }
        
        init(inputType: GraphQLInputType? = nil, outputType: GraphQLOutputType) {
            self.input = inputType
            self.output = outputType
        }
        
        init(inputAndOutputType type: GraphQLInputType & GraphQLOutputType) {
            self.input = type
            self.output = type
        }
        
//        var asOutputType: GraphQLOutputType { output }
        //var asInputType: GraphQLInputType { input ?? (output as! GraphQLInputType) }
        
        func map(input inputTransform: (GraphQLInputType) -> GraphQLInputType, output outputTransform: (GraphQLOutputType) -> GraphQLOutputType) -> Self {
            Self(
                inputType: input.map(inputTransform),
                outputType: outputTransform(output)
            )
        }
        
        func type(for usageCtx: GraphQLTypeUsageContext) -> GraphQLType? {
            switch usageCtx {
            case .input:
                return self.input
            case .output, .fieldInObject:
                return self.output
            }
        }
    }
    
    
    // key: field name on the root query thing // TODO improve and move away from putting everyting into the root query!!!
    private var queryHandlers: [String: GraphQLField] = [:]
    private var mutationHandlers: [String: GraphQLField] = [:]
    
    //private var cachedGraphQLInputTypes: [ObjectIdentifier: GraphQLInputType] = [:]
    //private var cachedGraphQLOutputTypes: [ObjectIdentifier: GraphQLOutputType] = [:]
    
    // NOTE: if a type doesn't have an entry in here, 
//    private var cachedGraphQLInputTypes: [TypeInformation: GraphQLInputType] = [:]
//    private var cachedGraphQLOutputTypes: [TypeInformation: GraphQLOutputType] = [:]
    
    private var cachedTypeMappings: [TypeInformation: TypesCacheEntry] = [:]
    
    private(set) var finalizedSchema: GraphQLSchema?
    
    var isMutable: Bool { finalizedSchema == nil }
    
    init() {}
    
    
    private func assertSchemaMutable(_ caller: StaticString = #function) throws {
        precondition(isMutable, "Invalid operation '\(caller)': schema is already finalized")
    }
    
    
    func add<H: Handler>(_ endpoint: Endpoint<H>) throws {
        let operation = endpoint[Operation.self]
        let commPattern = endpoint[CommunicationalPattern.self]
        switch (operation, commPattern) {
        case (.read, .requestResponse):
            try addQueryEndpoint(endpoint)
        case (.create, .requestResponse), (.update, .requestResponse), (.delete, .requestResponse):
            try addMutationEndpoint(endpoint)
        case (.read, .serviceSideStream):
            try addSubscriptionEndpoint(endpoint)
        default:
            throw SchemaError.unsupportedOpCommPatternTuple(operation, commPattern)
//        case (.read, .requestResponse):
//            try addUnaryEndpoint(endpoint)
//        case .serviceSideStream:
//            // TODO addSubscriptionEndpoint
//            fatalError("Not yet implemented")
//        case .clientSideStream:
//            // TODO model as a single function that expects an array as its parameter? (wouldn't really work bc these arguments would need to be all available when making the request, rather than sending them one after another...)
//            fatalError("Not (yet?) supported")
//        case .bidirectionalStream:
//            // Same reason as the client-side streams: only the service-streaming half would make sense (via a subscription), but im not so sure about the client-streaming part...
//            fatalError("Not (yet?) supported")
        }
    }
    
    
    private func addQueryEndpoint<H: Handler>(_ endpoint: Endpoint<H>) throws {
        try assertSchemaMutable()
//        guard let tmp_rootQueryFieldName = endpoint[Context.self].get(valueFor: TMP_GraphQLRootQueryFieldName.self) else {
//            throw SchemaError.noRootQueryFieldKeySpecified(endpoint)
//        }
        guard let endpointName = endpoint.getEndointName(format: .camelCase) else {
            throw SchemaError.noRootQueryFieldKeySpecified(endpoint)
        }
        guard !queryHandlers.keys.contains(endpointName) else {
            throw SchemaError.duplicateRootQueryFieldKey(endpointName)
        }
        queryHandlers[endpointName] = GraphQLField(
            //type: try toGraphQLOutputType(H.Response.Content.self),
            type: try toGraphQLOutputType(.init(type: H.Response.Content.self)),
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
                    .inspect { print("result for \(endpointName): \($0)") }
                    .map { $0 }
                
            },
            subscribe: nil
        )
    }
    
    
    
    private func addMutationEndpoint<H: Handler>(_ endpoint: Endpoint<H>) throws {
        try assertSchemaMutable()
        guard let endpointName = endpoint.getEndointName(format: .camelCase) else {
            throw SchemaError.noRootQueryFieldKeySpecified(endpoint)
        }
        guard !mutationHandlers.keys.contains(endpointName) else {
            throw SchemaError.duplicateRootQueryFieldKey(endpointName)
        }
        //let outTy = try toGraphQLOutputType(<#T##typeInfo: TypeInformation##TypeInformation#>)
        let outTy = try toGraphQLOutputType(.init(type: H.Response.Content.self))
        print(outTy)
        mutationHandlers[endpointName] = GraphQLField(
            type: try toGraphQLOutputType(.init(type: H.Response.Content.self)),
            args: try mapEndpointParametersToFieldArgs(endpoint),
            resolve: nil,
            subscribe: { source, args, context, eventLoopGroup, info in
                print("source: \(source)")
                print("args: \(args)")
                print("context: \(context)")
                print("eventLoopGroup: \(eventLoopGroup)")
                print("info: \(info)")
                fatalError("TODO")
            }
        )
        
    }
    
    
    private func addSubscriptionEndpoint<H: Handler>(_ endpoint: Endpoint<H>) throws {
        throw SchemaError.unsupportedOpCommPatternTuple(endpoint[Operation.self], endpoint[CommunicationalPattern.self])
    }
    
    
    
    private func toGraphQLInputType(_ typeInfo: TypeInformation) throws -> GraphQLInputType {
        do {
            if let inputType = try toGraphQLType(typeInfo, for: .input).input {
                return inputType
            } else {
                throw SchemaError.unableToConstructInputType(typeInfo, underlying: nil)
            }
        } catch {
            throw SchemaError.unableToConstructInputType(typeInfo, underlying: error)
        }
    }
    
    private func toGraphQLOutputType(_ typeInfo: TypeInformation) throws -> GraphQLOutputType {
        do {
            return try toGraphQLType(typeInfo, for: .output).output
        } catch {
            throw SchemaError.unableToConstructOutputType(typeInfo, underlying: error)
        }
    }
    
    
    private var currentTypeStack: Stack<TypeInformation> = []
    
    
    
    
    private func toGraphQLType(_ typeInfo: TypeInformation, for usageCtx: GraphQLTypeUsageContext) throws -> TypesCacheEntry {
        if let cached = cachedTypeMappings[typeInfo] {
            return cached
        }
        let result: TypesCacheEntry
        switch typeInfo {
        case .scalar, .repeated, .dictionary, .enum, .object, .reference:
            result = try _toGraphQLType(typeInfo, for: usageCtx).map(
                input: { GraphQLNonNull($0 as! GraphQLNullableType) },
                output: { GraphQLNonNull($0 as! GraphQLNullableType) }
            )
        case .optional(let wrappedValue):
            result = try _toGraphQLType(wrappedValue, for: usageCtx)
        }
        precondition(cachedTypeMappings.updateValue(result, forKey: typeInfo) == nil)
        return result
    }
    
    
    
    
    private func _toGraphQLType(_ typeInfo: TypeInformation, for usageCtx: GraphQLTypeUsageContext) throws -> TypesCacheEntry {
        precondition(!currentTypeStack.contains(typeInfo))
        
        currentTypeStack.push(typeInfo)
        defer {
            precondition(currentTypeStack.pop() == typeInfo)
        }
        
        switch typeInfo {
        case .scalar(let primitiveType):
            switch primitiveType {
            case .null:
                fatalError()
            case .bool:
                return .init(inputAndOutputType: GraphQLBoolean)
            case .float:
                return .init(inputAndOutputType: GraphQLFloat)
            case .double:
                return .init(inputAndOutputType: GraphQLFloat)
            case .int32:
                return .init(inputAndOutputType: GraphQLInt)
            case .int8, .uint8, .int16, .uint16, .uint32:
                return .init(inputAndOutputType: GraphQLInt)
            case .int, .uint, .int64, .uint64:
                return .init(inputAndOutputType: GraphQLInt)
            case .string:
                return .init(inputAndOutputType: GraphQLString)
            case .url:
                // We could also define our own URL scalar, though that might not work with all clients...
                //return .init(inputAndOutputType: GraphQLString) // TODO this will absolutely break.
                return .init(inputAndOutputType: try GraphQLScalarType(
                    name: "URL",
                    description: "Uniform Resource Locator",
                    serialize: { (input: Any) throws -> Map in
                        print(type(of: input), input)
                        fatalError("TODO")
                    },
                    parseValue: { (input: Map) throws -> Map in
                        print(type(of: input), input)
                        fatalError("TODO")
                    },
                    parseLiteral: { (input: Value) throws -> Map in
                        print(type(of: input), input)
                        fatalError("TODO")
                    }
                ))
            case .uuid:
                // what about GraphQLID?
                return .init(inputAndOutputType: GraphQLString) // custom scalar?
            case .date:
                return .init(inputAndOutputType: GraphQLFloat) // custom scalar?
            case .data:
                // TODO does this also necessitate a custom type?
                return .init(inputAndOutputType: GraphQLList(GraphQLInt))
            }
        case .repeated(let element):
            return .init(inputAndOutputType: GraphQLList(try toGraphQLType(element, for: usageCtx).type(for: usageCtx)!))
        case let .dictionary(key, value):
            fatalError("dict: \(key) \(value)")
        case .optional(let wrappedValue):
            fatalError("optional: \(wrappedValue)")
        case let .enum(name, rawValueType: _, cases, context: _):
            if typeInfo.isEqual(to: Never.self) {
//                throw SchemaError.unexpectedNeverType
                // The Never type can't really be represented in GraphQL.
                // We essentially have 2 options:
                // 1. Map this into a field w/ an empty return type (i.e. a type that has no fields, and thus can't be instantiatd. though the same thing doesnt work for enums...)
                let desc = "The Never type exists to model a type which cannot be instantiated, and is used to indicate that a field does not return a result, but instead will result in a guaranteed error."
                return .init(
                    inputType: try GraphQLInputObjectType(
                        name: "Never",
                        description: desc,
                        fields: ["_": InputObjectField(type: GraphQLInt)]
                    ),
                    outputType: try GraphQLObjectType(
                        name: "Never",
                        description: desc,
                        fields: ["_": GraphQLField(type: GraphQLInt)]
                    )
                )
            }
            return .init(inputAndOutputType: try GraphQLEnumType(
                name: name.name,
                description: nil,
                values: cases.mapIntoDict { enumCase -> (String, GraphQLEnumValue) in
                    (enumCase.name, GraphQLEnumValue(value: .string(enumCase.name)))
                }
            ))
        case let .object(name, properties, context: _):
            // TODO we have to make sure that the name used here is one we can also get from a raw Any.Type object (though of course we could just call out to ATI again), since in the case of recursive/circular types, we need to be able to create a GraphQLTypeReference object (which works based on the name...)
            // ^^^ TODO is this the correct name? what about generics? there's also an `absoluteName()` function, maybe that's better...
            return .init(
                inputType: try GraphQLInputObjectType(
                    name: "\(name.name)__Input",
                    fields: try properties.mapIntoDict { property -> (String, InputObjectField) in
                        (property.name, InputObjectField(type: try toGraphQLInputType(property.type)))
                    }
                ),
                outputType: try GraphQLObjectType(
                    name: name.name,
                    description: nil, // TODO?
                    fields: try properties.mapIntoDict { property -> (String, GraphQLField) in
                        (property.name, GraphQLField(type: try toGraphQLOutputType(property.type)))
                    }
                )
            )
        case .reference(let referenceKey):
            fatalError("reference: \(referenceKey)")
        }
    }
    
    
    private func mapEndpointParametersToFieldArgs<H>(_ endpoint: Endpoint<H>) throws -> GraphQLArgumentConfigMap {
        guard !endpoint.parameters.isEmpty else {
            return [:]
        }
        var argsMap: GraphQLArgumentConfigMap = [:]
        for parameter in endpoint.parameters {
            argsMap[parameter.name] = GraphQLArgument(
                type: try toGraphQLInputType(.init(type: parameter.originalPropertyType)),
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
        self.finalizedSchema = try! GraphQLSchema(
            query: GraphQLObjectType(
                name: "Query",
                description: "_todo_",
                fields: self.queryHandlers // TODO better mapping here!
                //interfaces: <#T##[GraphQLInterfaceType]#>,
                //isTypeOf: <#T##GraphQLIsTypeOf?##GraphQLIsTypeOf?##(_ source: Any, _ eventLoopGroup: EventLoopGroup, _ info: GraphQLResolveInfo) throws -> Bool#>
            ),
            mutation: self.mutationHandlers.isEmpty ? nil : GraphQLObjectType(
                name: "Mutation",
                description: "todo",
                fields: self.mutationHandlers
            )
            //subscription: <#T##GraphQLObjectType?#>,
            //types: <#T##[GraphQLNamedType]#>,
            //directives: <#T##[GraphQLDirective]#>
        )
        return finalizedSchema!
    }
}

