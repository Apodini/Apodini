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


class GraphQLSchemaBuilder {
    enum SchemaError: Swift.Error {
        case unableToConstructInputType(TypeInformation, underlying: Swift.Error?)
        case unableToConstructOutputType(TypeInformation, underlying: Swift.Error)
        // Two or more handlers have defined the same key
        case duplicateEndpointNames(String)
        case unsupportedOpCommPatternTuple(Apodini.Operation, CommunicationalPattern)
        /// There must be at least one query handler (i.e. an unary handler w/ a `.read` operation type) in the web service
        case missingQueryHandler
        case other(String)
    }
    
    
    private enum TypeUsageContext {
        case input, output
    }
    
    
    private struct TypesCacheEntry {
        let input: GraphQLInputType?
        let output: GraphQLOutputType
        
        init(inputType: GraphQLInputType? = nil, outputType: GraphQLOutputType) {
            self.input = inputType
            self.output = outputType
        }
        
        init(inputAndOutputType type: GraphQLInputType & GraphQLOutputType) {
            self.input = type
            self.output = type
        }
        
        func map(
            input inputTransform: (GraphQLInputType) -> GraphQLInputType,
            output outputTransform: (GraphQLOutputType) -> GraphQLOutputType
        ) -> Self {
            Self(
                inputType: input.map(inputTransform),
                outputType: outputTransform(output)
            )
        }
        
        func type(for usageCtx: TypeUsageContext) -> GraphQLType? {
            switch usageCtx {
            case .input:
                return self.input
            case .output:
                return self.output
            }
        }
    }
    
    
    // key: field name on the root query thing
    private var queryHandlers: [String: GraphQLField] = [:]
    private var mutationHandlers: [String: GraphQLField] = [:]
    
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
            try addQueryOrMutationEndpoint(to: &queryHandlers, endpoint: endpoint)
        case (.create, .requestResponse), (.update, .requestResponse), (.delete, .requestResponse):
            try addQueryOrMutationEndpoint(to: &mutationHandlers, endpoint: endpoint)
        case (.read, .serviceSideStream):
            try addSubscriptionEndpoint(endpoint)
        default:
            throw SchemaError.unsupportedOpCommPatternTuple(operation, commPattern)
        }
    }
    
    
    private func addQueryOrMutationEndpoint<H: Handler>(to handlers: inout [String: GraphQLField], endpoint: Endpoint<H>) throws {
        try assertSchemaMutable()
        let endpointName = endpoint.getEndointName(.noun, format: .camelCase)
        guard !handlers.keys.contains(endpointName) else {
            throw SchemaError.duplicateEndpointNames(endpointName)
        }
        handlers[endpointName] = GraphQLField(
            type: try toGraphQLOutputType(.init(type: H.Response.Content.self)),
            args: try mapEndpointParametersToFieldArgs(endpoint),
            resolve: makeQueryOrMutationFieldResolver(for: endpoint),
            subscribe: nil
        )
    }
    
    
    private func makeQueryOrMutationFieldResolver<H: Handler>(for endpoint: Endpoint<H>) -> GraphQLFieldResolve {
        let defaults = endpoint[DefaultValueStore.self]
        let delegateFactory = endpoint[DelegateFactory<H, GraphQLInterfaceExporter>.self]
        return { _, args, _, eventLoopGroup, _ -> EventLoopFuture<Any?> in
            let delegate = delegateFactory.instance()
            let decodingStrategy = GraphQLEndpointDecodingStrategy().applied(to: endpoint).typeErased
            let responseFuture: EventLoopFuture<Apodini.Response<H.Response.Content>> = decodingStrategy
                .decodeRequest(from: args, with: DefaultRequestBasis(), with: eventLoopGroup.next())
                .insertDefaults(with: defaults)
                .cache()
                .evaluate(on: delegate)
            return responseFuture
                .map { $0.content }
        }
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
    
    
    private func toGraphQLType(_ typeInfo: TypeInformation, for usageCtx: TypeUsageContext) throws -> TypesCacheEntry {
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
            result = try _toGraphQLType(wrappedValue, for: usageCtx).map(
                input: { (($0 as? GraphQLNonNull)?.ofType as? GraphQLInputType) ?? $0 },
                output: { ($0 as? GraphQLNonNull)?.ofType as! GraphQLOutputType }
            )
        }
        precondition(cachedTypeMappings.updateValue(result, forKey: typeInfo) == nil)
        return result
    }
    
    
    private func _toGraphQLType(_ typeInfo: TypeInformation, for usageCtx: TypeUsageContext) throws -> TypesCacheEntry { // swiftlint:disable:this cyclomatic_complexity line_length
        precondition(!currentTypeStack.contains(typeInfo))
        if let cached = cachedTypeMappings[typeInfo] {
            return cached
        }
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
            let type = try toGraphQLType(element, for: usageCtx)
            return .init(
                inputType: GraphQLList(type.input!),
                outputType: GraphQLList(type.output)
            )
        case let .dictionary(key, value):
            fatalError("dict: \(key) \(value)")
        case .optional(let wrappedValue):
            fatalError("optional: \(wrappedValue)")
        case let .enum(name, rawValueType: _, cases, context: _):
            if typeInfo.isEqual(to: Never.self) {
                // The Never type can't really be represented in GraphQL.
                // We essentially have 2 options:
                // 1. Map this into a field w/ an empty return type (i.e. a type that has no fields, and thus can't be instantiatd. though the same thing doesnt work for enums...)
                let desc = "The Never type exists to model a type which cannot be instantiated, and is used to indicate that a field does not return a result, but instead will result in a guaranteed error." // swiftlint:disable:this line_length
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
                name: name.buildName(),
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
                    name: "\(name.buildName())__Input",
                    fields: try properties.mapIntoDict { property -> (String, InputObjectField) in
                        (property.name, InputObjectField(type: try toGraphQLInputType(property.type)))
                    }
                ),
                outputType: try GraphQLObjectType(
                    name: name.buildName(),
                    description: nil,
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
                description: nil,
                defaultValue: try { () -> Map? in
                    if let paramDefaultValueBlock = parameter.typeErasedDefaultValue {
                        return try map(from: paramDefaultValueBlock())
                    } else {
                        // The endpoint parameter does not specify a default value,
                        // meaning that the only adjustment we make is to default Optionals to `nil` if possible
                        return parameter.nilIsValidValue ? .null : nil
                    }
                }()
            )
        }
        return argsMap
    }
    
    
    @discardableResult
    func finalize() throws -> GraphQLSchema {
        if let finalizedSchema = finalizedSchema {
            return finalizedSchema
        }
        guard !queryHandlers.isEmpty else {
            throw SchemaError.missingQueryHandler
        }
        self.finalizedSchema = try GraphQLSchema(
            query: GraphQLObjectType(
                name: "Query",
                description: "The query type contains all query-mapped handlers in a web service, i.e. all `Handler`s with a `.read` operation type and the unary communicational pattern.", // swiftlint:disable:this line_length
                fields: queryHandlers
            ),
            mutation: mutationHandlers.isEmpty ? nil : GraphQLObjectType(
                name: "Mutation",
                description: nil,
                fields: mutationHandlers
            )
        )
        return finalizedSchema! // Force-unwrap is fine bc we just assigned the variable above
    }
}
