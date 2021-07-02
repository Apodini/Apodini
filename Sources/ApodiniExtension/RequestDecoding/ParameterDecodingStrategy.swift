//
//  ParameterDecodingStrategy.swift
//  
//
//  Created by Max Obermeier on 28.06.21.
//

import Foundation
import Apodini
import ApodiniUtils

// MARK: ParameterDecodingStrategy

/// A strategy that can decode a certain ``Element`` from a certain ``Input``.
///
/// A ``ParameterDecodingStrategy`` carries the relevant information about
/// a certain parameter and uses this information when its ``decode(from:)`` method
/// is called to obtain an instance of ``Element`` from the given instance of ``Input``.
public protocol ParameterDecodingStrategy {
    /// The type this strategy can instantiate.
    associatedtype Element: Decodable
    /// The type this strategy requires to instantiate an ``Element``
    associatedtype Input = Data
    
    /// This function instantiates a type of ``ParameterDecodingStrategy/Element`` from the given `input`.
    func decode(from input: Input) throws -> Element
}


// MARK: AnyParameterDecodingStrategy

public extension ParameterDecodingStrategy {
    /// Erases the type from this ``ParameterDecodingStrategy``.
    var typeErased: AnyParameterDecodingStrategy<Element, Input> {
        AnyParameterDecodingStrategy(self)
    }
}

/// A type-erased wrapper around any ``ParameterDecodingStrategy``.
public struct AnyParameterDecodingStrategy<E: Decodable, I>: ParameterDecodingStrategy {
    private let _decode: (I) throws -> E
    
    internal init<S: ParameterDecodingStrategy>(_ strategy: S) where S.Element == E, S.Input == I {
        self._decode = strategy.decode
    }
    
    public func decode(from input: I) throws -> E {
        try _decode(input)
    }
}


// MARK: TransformingStrategy

/// A ``ParameterDecodingStrategy`` that forms a transition between a wrapped ``ParameterDecodingStrategy`` `S`
/// and a parent ``ParameterDecodingStrategy`` with ``ParameterDecodingStrategy/Input`` type `I`.
///
/// This strategy allows for reuse of ``ParameterDecodingStrategy`` with a more basic ``ParameterDecodingStrategy/Input`` than
/// the one you are acutally using. E.g. many of the predefined strategies have input type `Data`.
/// If your input type is a complete request, you can probably reuse those predefined strategies by extracting the body
/// from the request.
public struct TransformingParameterStrategy<S: ParameterDecodingStrategy, I>: ParameterDecodingStrategy {
    private let transformer: (I) throws -> S.Input
    private let strategy: S
    
    /// Create a new ``TransformingParameterStrategy`` from the given `strategy` by providing a
    /// `transformer` which can extract the `strategy`'s ``ParameterDecodingStrategy/Input`` from
    /// a more general new ``ParameterDecodingStrategy/Input`` type `I`.
    public init(_ strategy: S, using transformer: @escaping (I) throws -> S.Input) {
        self.strategy = strategy
        self.transformer = transformer
    }
    
    public func decode(from input: I) throws -> S.Element {
        try strategy.decode(from: transformer(input))
    }
}


// MARK: Implementations

/// A ``ParameterDecodingStrategy`` that ignores its actual input and instead always
/// return the same `element`.
public struct GivenStrategy<E: Decodable, I>: ParameterDecodingStrategy {
    private let element: E
    
    /// Create a new ``GivenStrategy`` that always returns `element`.
    public init(_ element: E) {
        self.element = element
    }
    
    public func decode(from input: I) throws -> E {
        element
    }
}

/// A ``ParameterDecodingStrategy`` that ignores its actual input and instead always
/// throws the same `error`.
public struct ThrowingStrategy<E: Decodable, I>: ParameterDecodingStrategy {
    private let error: Error
    
    /// Create a new ``ThrowingStrategy`` that always throws `error`.
    public init(_ error: Error) {
        self.error = error
    }
    
    public func decode(from input: I) throws -> E {
        throw error
    }
}

/// A ``ParameterDecodingStrategy`` that uses a certain `AnyDecoder` and a ``DecodingPattern``
/// to decode the pattern's ``DecodingPattern/Element``.
public struct PlainPatternStrategy<P: DecodingPattern>: ParameterDecodingStrategy {
    public typealias Content = P.Element
    
    private let decoder: AnyDecoder
    
    /// Create a new ``PlainPatternStrategy`` that uses the given `decoder`.
    public init(_ decoder: AnyDecoder) {
        self.decoder = decoder
    }
    
    public func decode(from data: Data) throws -> P.Element {
        try decoder.decode(P.self, from: data).value
    }
}

/// A ``ParameterDecodingStrategy`` that uses a certain `AnyDecoder` and a ``DecodingPattern``
/// to decode the pattern's ``DecodingPattern/Element`` just as ``PlainPatternStrategy``.
///
/// - Note: This strategy allows for usage of ``DynamicNamePattern``. On decoding, the strategy provides
/// this pattern with its `name` property.
public struct NamedChildPatternStrategy<P: DecodingPattern>: ParameterDecodingStrategy {
    public typealias Content = P.Element
    
    private let name: String
    
    private let decoder: AnyDecoder
    
    /// Create a new ``NamedChildPatternStrategy``.
    ///
    /// - Parameters:
    ///     - `name`:  The name that is provided to the ``DynamicNamePattern`` if that is part of `P`
    ///     - `decoder`: The decoder that is used to decode `P` from the input `Data`
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

/// A ``ParameterDecodingStrategy`` that uses a certain `AnyDecoder` and a ``DecodingPattern``
/// to decode the pattern's ``DecodingPattern/Element`` just as ``PlainPatternStrategy``.
///
/// - Note: This strategy allows for usage of both ``DynamicNamePattern`` and ``DynamicIndexPattern``.
/// On decoding, the strategy provides the first with its static `name` property. The index required for the
/// ``DynamicIndexPattern`` is obtained from the second field in ``decode(from:)``'s `input`.
public struct IndexedNamedChildPatternStrategy<P: DecodingPattern>: ParameterDecodingStrategy {
    public typealias Content = P.Element

    private let decoder: AnyDecoder
    
    private let name: String

    /// Create a new ``IndexedNamedChildPatternStrategy``.
    ///
    /// - Parameters:
    ///     - `name`:  The name that is provided to the ``DynamicNamePattern`` if that is part of `P`
    ///     - `decoder`: The decoder that is used to decode `P` from the input `Data`
    public init(_ name: String, _ decoder: AnyDecoder) {
        self.name = name
        self.decoder = decoder
    }

    public func decode(from input: (Data, Int)) throws -> P.Element {
        if let nameWrapper = namedChildStrategyFieldName.currentValue {
            nameWrapper.name = name
        } else {
            namedChildStrategyFieldName.currentValue = FieldName(name)
        }
        
        if let indexWrapper = indexStrategyIndex.currentValue {
            indexWrapper.index = input.1
        } else {
            indexStrategyIndex.currentValue = Index(input.1)
        }
        
        return try decoder.decode(P.self, from: input.0).value
    }
}


struct InterfaceExporterLegacyParameterStrategy<IE: LegacyInterfaceExporter, E: Codable>: ParameterDecodingStrategy {
    let parameter: EndpointParameter<E>
    let exporter: IE
    
    func decode(from input: IE.ExporterRequest) throws -> E {
        let result = try exporter.retrieveParameter(parameter, for: input)
        
        switch result {
        case let .some(.some(value)):
            return value
        case .some(.none):
            throw DecodingError.valueNotFound(E.self, DecodingError.Context(
                codingPath: [],
                debugDescription: "Exporter \(IE.self) encountered an explicit 'nil' value for \(parameter) in \(input).",
                underlyingError: nil))
        case .none:
            throw DecodingError.keyNotFound(parameter.name, DecodingError.Context(
                codingPath: [],
                debugDescription: "Exporter \(IE.self) could not decode a value for \(parameter) from \(input).",
                underlyingError: nil))
        }
    }
}
