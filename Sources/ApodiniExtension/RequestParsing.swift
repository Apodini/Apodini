//
//  RequestParsing.swift
//  
//
//  Created by Max Obermeier on 24.06.21.
//

import Foundation
import OpenCombine
import Apodini
import ApodiniUtils

public protocol ParsingStrategy {
    func strategy<Element: Decodable>(for parameter: Parameter<Element>) -> AnyParameterParsingStrategy<Element>
}

public protocol EndpointParameterParsingStrategy {
    func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterParsingStrategy<Element>
}

public struct EndpointParameterBasedParsingStrategy<S: EndpointParameterParsingStrategy>: ParsingStrategy {
    private let strategy: S
    
    private let endpointParameters: [UUID: AnyEndpointParameter]
    
    public init(_ strategy: S, on endpoint: AnyEndpoint) {
        self.strategy = strategy
        self.endpointParameters = endpoint[EndpointParameters.self].reduce(into: [UUID: AnyEndpointParameter](), { storage, parameter in
            storage[parameter.id] = parameter
        })
    }
    
    public func strategy<Element: Decodable>(for parameter: Parameter<Element>) -> AnyParameterParsingStrategy<Element> {
        guard let parameter = endpointParameters[parameter.id] as? CanCallEndpointParameterParsingStrategy else {
            fatalError("Couldn't find matching 'EndpointParameter' with id \(parameter.id) while determining 'ParsingStrategy'.")
        }
        
        return parameter.call(strategy)
    }
}

private protocol CanCallEndpointParameterParsingStrategy {
    func call<S: EndpointParameterParsingStrategy, Element: Decodable>(_ strategy: S) -> AnyParameterParsingStrategy<Element>
}

extension EndpointParameter: CanCallEndpointParameterParsingStrategy {
    func call<S, V>(_ strategy: S) -> AnyParameterParsingStrategy<V> where S : EndpointParameterParsingStrategy, V : Decodable {
        let baseStrategy = strategy.strategy(for: self)
        if nilIsValidValue { // V == Optional<Type>
            if let typedStrategy = OptionalWrappingStrategy(baseStrategy: baseStrategy).typeErased as? AnyParameterParsingStrategy<V> {
                return typedStrategy
            }
            fatalError("Internal logic of 'EndpointParameter.call(_:)' is broken: wrong type in nil case.")
        } else { // V == Type
            if let typedStrategy = baseStrategy as? AnyParameterParsingStrategy<V> {
                return typedStrategy
            }
            fatalError("Internal logic of 'EndpointParameter.call(_:)' is broken: wrong type in base case.")
        }
    }
}

private struct OptionalWrappingStrategy<P: ParameterParsingStrategy>: ParameterParsingStrategy {
    let baseStrategy: P
    
    func decode(from decoder: Decoder) throws -> Optional<P.Element> {
        do {
            return .some(try baseStrategy.decode(from: decoder))
        } catch DecodingError.valueNotFound(_, _) {
            return .none
        }
    }
}

// MARK: ParameterParsingStrategy

public protocol ParameterParsingStrategy {
    associatedtype Element: Decodable
    
    func decode(from decoder: Decoder) throws -> Element
}

public extension ParameterParsingStrategy {
    var typeErased: AnyParameterParsingStrategy<Element> {
        AnyParameterParsingStrategy(self)
    }
}

public struct AnyParameterParsingStrategy<E: Decodable>: ParameterParsingStrategy {
    private let _decode: (Decoder) throws -> E
    
    internal init<S: ParameterParsingStrategy>(_ strategy: S) where S.Element == E {
        self._decode = strategy.decode
    }
    
    public func decode(from decoder: Decoder) throws -> E {
        try _decode(decoder)
    }
}

public struct GivenStrategy<E: Decodable>: ParameterParsingStrategy {
    private let element: E
    
    public init(_ element: E) {
        self.element = element
    }
    
    public func decode(from decoder: Decoder) throws -> E {
        element
    }
}

public struct IdentityStrategy<E: Decodable>: ParameterParsingStrategy {
    public typealias Element = E
    
    public func decode(from decoder: Decoder) throws -> E {
        try E(from: decoder)
    }
}

public struct NamedChildStrategy<E: Decodable>: ParameterParsingStrategy {
    public typealias Element = E
    
    private let name: String
    
    public init(_ name: String) {
        self.name = name
    }
    
    public func decode(from decoder: Decoder) throws -> E {
        let container = try decoder.container(keyedBy: String.self)
        return try container.decode(E.self, forKey: name)
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
