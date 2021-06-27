//
//  RequestDecodingStrategies.swift
//  
//
//  Created by Max Obermeier on 24.06.21.
//

import Foundation
import Apodini
import ApodiniUtils

// MARK: Global Decoding Strategies

public struct TransformingStrategy<S: DecodingStrategy, I>: DecodingStrategy {
    private let transformer: (I) throws -> S.Input
    private let strategy: S
    
    public init(_ strategy: S, using transformer: @escaping (I) throws -> S.Input) {
        self.strategy = strategy
        self.transformer = transformer
    }
    
    public func strategy<Element>(for parameter: Parameter<Element>) -> AnyParameterDecodingStrategy<Element, I> where Element : Decodable, Element : Encodable {
        TransformingParameterStrategy(strategy.strategy(for: parameter), using: transformer).typeErased
    }
}

public extension DecodingStrategy {
    func transformed<I>(_ transformer: @escaping (I) throws -> Self.Input) -> TransformingStrategy<Self, I> {
        TransformingStrategy(self, using: transformer)
    }
}

public struct TransformingEndpointStrategy<S: EndpointDecodingStrategy, I>: EndpointDecodingStrategy {
    private let transformer: (I) throws -> S.Input
    private let strategy: S
    
    public init(_ strategy: S, using transformer: @escaping (I) throws -> S.Input) {
        self.strategy = strategy
        self.transformer = transformer
    }
    
    public func strategy<Element>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, I> where Element : Decodable, Element : Encodable {
        TransformingParameterStrategy(strategy.strategy(for: parameter), using: transformer).typeErased
    }
}

public extension EndpointDecodingStrategy {
    func transformed<I>(_ transformer: @escaping (I) throws -> Self.Input) -> TransformingEndpointStrategy<Self, I> {
        TransformingEndpointStrategy(self, using: transformer)
    }
}

public struct TransformingBaseStrategy<S: BaseDecodingStrategy, Input>: BaseDecodingStrategy {
    private let transformer: (Input) throws -> S.Input
    private let strategy: S
    
    public init(_ strategy: S, using transformer: @escaping (Input) throws -> S.Input) {
        self.strategy = strategy
        self.transformer = transformer
    }
    
    public func strategy<Element, I>(for parameter: I) -> AnyParameterDecodingStrategy<Element, Input> where Element : Decodable, I : Identifiable, I.ID == UUID {
        TransformingParameterStrategy(strategy.strategy(for: parameter), using: transformer).typeErased
    }
}

public extension BaseDecodingStrategy {
    func transformed<I>(_ transformer: @escaping (I) throws -> Self.Input) -> TransformingBaseStrategy<Self, I> {
        TransformingBaseStrategy(self, using: transformer)
    }
}


public struct NumberOfContentParameterDependentStrategy<Input>: EndpointDecodingStrategy {
    private let strategy: AnyEndpointDecodingStrategy<Input>
    
    init<One: EndpointDecodingStrategy, Many: EndpointDecodingStrategy>(
        for endpoint: AnyEndpoint,
        using one: One,
        or many: Many) where One.Input == Input, Many.Input == Input {
        let onlyOneContentParameter = 1 <= endpoint[EndpointParameters.self].reduce(0, { count, parameter in
            count + (parameter.parameterType == .content ? 1 : 0)
        })
                                            
        if onlyOneContentParameter {
            self.strategy = one.typeErased
        } else {
            self.strategy = many.typeErased
        }
    }
    
    
    public func strategy<Element>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Input> where Element : Decodable, Element : Encodable {
        strategy.strategy(for: parameter)
    }
}

public extension NumberOfContentParameterDependentStrategy where Input == Data {
    static func oneIdentityOrAllNamedContentStrategy(_ decoder: AnyDecoder, for endpoint: AnyEndpoint) -> Self {
        self.init(for: endpoint, using: AllIdentityStrategy(decoder), or: AllNamedStrategy(decoder))
    }
}

public struct AllNamedStrategy: EndpointDecodingStrategy {
    private let decoder: AnyDecoder
    
    public init(_ decoder: AnyDecoder) {
        self.decoder = decoder
    }
    
    public func strategy<Element>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Data> where Element : Decodable, Element : Encodable {
        NamedChildPatternStrategy<DynamicNamePattern<Element>>(parameter.name, decoder).typeErased
    }
}

public struct AllIdentityStrategy: BaseDecodingStrategy {
    private let decoder: AnyDecoder
    
    public init(_ decoder: AnyDecoder) {
        self.decoder = decoder
    }
    
    public func strategy<Element, I>(for parameter: I) -> AnyParameterDecodingStrategy<Element, Data> where Element : Decodable, I: Identifiable {
        PlainPatternStrategy<IdentityPattern<Element>>(decoder).typeErased
    }
}

public struct ParameterTypeSpecific<P: EndpointDecodingStrategy, B: EndpointDecodingStrategy>: EndpointDecodingStrategy where P.Input == B.Input {
    private let backup: B
    private let primary: P
    private let parameterType: ParameterType
    
    public init(_ type: ParameterType = .content, using primary: P, otherwise backup: B) {
        self.backup = backup
        self.primary = primary
        self.parameterType = type
    }
    
    public func strategy<Element>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, P.Input> where Element : Decodable, Element : Encodable {
        if parameter.parameterType == self.parameterType {
            return primary.strategy(for: parameter)
        } else {
            return backup.strategy(for: parameter)
        }
    }
}

public struct IdentifierBasedStrategy<Input>: BaseDecodingStrategy {
    private var strategies = [UUID: Any]()
    
    public init() {}
    
    public func strategy<Element, I>(for parameter: I) -> AnyParameterDecodingStrategy<Element, Input> where Element : Decodable, I : Identifiable, I.ID == UUID {
        guard let strategy = strategies[parameter.id] as? AnyParameterDecodingStrategy<Element, Input> else {
            fatalError("'IdentifierBasedStrategy' is missing strategy for parameter with id \(parameter.id)!")
        }
        return strategy
    }
    
    public func with<P: ParameterDecodingStrategy, I: Identifiable>(strategy: P, for parameter: I) -> Self where I.ID == UUID, P.Input == Input {
        var selfCopy = self
        selfCopy.strategies[parameter.id] = strategy.typeErased
        return selfCopy
    }
}


// MARK: Parameter Decoding Strategies

public struct TransformingParameterStrategy<S: ParameterDecodingStrategy, I>: ParameterDecodingStrategy {
    private let transformer: (I) throws -> S.Input
    private let strategy: S
    
    public init(_ strategy: S, using transformer: @escaping (I) throws -> S.Input) {
        self.strategy = strategy
        self.transformer = transformer
    }
    
    public func decode(from input: I) throws -> S.Element {
        try strategy.decode(from: transformer(input))
    }
}


public struct GivenStrategy<E: Decodable, I>: ParameterDecodingStrategy {
    private let element: E
    
    public init(_ element: E) {
        self.element = element
    }
    
    public func decode(from input: I) throws -> E {
        element
    }
}

public struct ThrowingStrategy<E: Decodable, I>: ParameterDecodingStrategy {
    private let error: Error
    
    public init(_ error: Error) {
        self.error = error
    }
    
    public func decode(from input: I) throws -> E {
        throw error
    }
}

public struct PlainPatternStrategy<P: DecodingPattern>: ParameterDecodingStrategy {
    public typealias Content = P.Element
    
    private let decoder: AnyDecoder
    
    public init(_ decoder: AnyDecoder) {
        self.decoder = decoder
    }
    
    public func decode(from data: Data) throws -> P.Element {
        try decoder.decode(P.self, from: data).value
    }
}

public struct NamedChildPatternStrategy<P: DecodingPattern>: ParameterDecodingStrategy {
    public typealias Content = P.Element
    
    private let name: String
    
    private let decoder: AnyDecoder
    
    public init(_ name: String, _ decoder: AnyDecoder) {
        self.name = name
        self.decoder = decoder
    }
    
    public func decode(from data: Data) throws -> P.Element {
        if let nameWrapper = namedChildStrategyFieldName.currentValue {
            nameWrapper.name = name
        } else {
            namedChildStrategyFieldName.currentValue = FieldName(name)
        }
        return try decoder.decode(P.self, from: data).value
    }
}

// MARK: DecodingPattern

public protocol DecodingPattern: Decodable {
    associatedtype Element: Decodable
    
    var value: Element { get }
}

public struct IdentityPattern<E: Decodable>: DecodingPattern {
    public let value: E
    
    public init(from decoder: Decoder) throws {
        value = try E(from: decoder)
    }
}

/// - Note: Only works with ``NamedChildPatternStrategy``
public struct DynamicNamePattern<E: Decodable>: DecodingPattern {
    public let value: E
    
    public init(from decoder: Decoder) throws {
        guard let name = namedChildStrategyFieldName.currentValue?.name else {
            fatalError("DynamicNamePattern was used without setting field name prior to decoding!")
        }
        let container = try decoder.container(keyedBy: String.self)
        value = try container.decode(E.self, forKey: name)
    }
}

private let namedChildStrategyFieldName = ThreadSpecificVariable<FieldName>()

private class FieldName {
    var name: String
    
    init(_ name: String) {
        self.name = name
    }
}

extension String: CodingKey {
    public init?(intValue: Int) {
        self = String(describing: intValue)
    }
    
    public init?(stringValue: String) {
        self = stringValue
    }
    
    public var stringValue: String {
        self
    }
    
    public var intValue: Int? {
        Int(self)
    }
}
