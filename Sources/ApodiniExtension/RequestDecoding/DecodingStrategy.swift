//
//  DecodingStrategy.swift
//  
//
//  Created by Max Obermeier on 28.06.21.
//

import Foundation
import Apodini
import ApodiniUtils


// MARK: DecodingStrategy

/// A strategy describing how a certain Apodini `Parameter` can be decoded from
/// a fixed ``Input`` type.
///
/// A ``DecodingStrategy`` can be used to transform a certain ``Input`` to an
/// Apodini `Request`.  While the ``DecodingStrategy`` only helps implementing
/// the Apodini `Request/retrieveParameter(_:)`, a ``RequestBasis`` can
/// be used to provide the missing information. This proccess is implemented in
/// ``DecodingStrategy/decodeRequest(from:with:with:)``.
public protocol DecodingStrategy {
    /// The type which the ``ParameterDecodingStrategy``s returned by ``strategy(for:)``
    /// take as an input for ``ParameterDecodingStrategy/decode(from:)``.
    associatedtype Input = Data
    
    /// The actual strategy for determining a suitable ``ParameterDecodingStrategy`` for the
    /// given `parameter`.
    func strategy<Element: Decodable>(for parameter: Parameter<Element>) -> AnyParameterDecodingStrategy<Element, Input>
}


// MARK: AnyDecodingStrategy

public extension DecodingStrategy {
    /// Erases the type from this ``DecodingStrategy``.
    var typeErased: AnyDecodingStrategy<Input> {
        AnyDecodingStrategy(self)
    }
}

/// A type-erased wrapper around any ``DecodingStrategy``.
public struct AnyDecodingStrategy<I>: DecodingStrategy {
    private let caller: DecodingStrategyCaller
    
    init<S: DecodingStrategy>(_ strategy: S) where S.Input == I {
        self.caller = SomeDecodingStrategyCaller(strategy: strategy)
    }
    
    public func strategy<Element>(for parameter: Parameter<Element>)
        -> AnyParameterDecodingStrategy<Element, I> where Element: Decodable, Element: Encodable {
        caller.call(with: parameter)
    }
}

private protocol DecodingStrategyCaller {
    func call<E: Decodable, I>(with parameter: Parameter<E>) -> AnyParameterDecodingStrategy<E, I>
}

private struct SomeDecodingStrategyCaller<S: DecodingStrategy>: DecodingStrategyCaller {
    let strategy: S
    
    func call<E: Decodable, I>(with parameter: Parameter<E>) -> AnyParameterDecodingStrategy<E, I> {
        guard let parameterStrategy = strategy.strategy(for: parameter) as? AnyParameterDecodingStrategy<E, I> else {
            fatalError("'SomeDecodingStrategyCaller' was used with wrong input type (\(I.self) instead of \(S.Input.self))")
        }
        return parameterStrategy
    }
}


// MARK: TransformingStrategy

/// A ``DecodingStrategy`` that forms a transition between a wrapped ``DecodingStrategy`` `S`
/// and a parent ``DecodingStrategy`` with ``DecodingStrategy/Input`` type `I`.
///
/// This strategy allows for reuse of ``DecodingStrategy`` with a more basic ``DecodingStrategy/Input`` than
/// the one you are acutally using. E.g. many of the predefined strategies have input type `Data`.
/// If your input type is a complete request, you can probably reuse those predefined strategies by extracting the body
/// from the request.
public struct TransformingStrategy<S: DecodingStrategy, I>: DecodingStrategy {
    private let transformer: (I) throws -> S.Input
    private let strategy: S
    
    init(_ strategy: S, using transformer: @escaping (I) throws -> S.Input) {
        self.strategy = strategy
        self.transformer = transformer
    }
    
    public func strategy<Element>(for parameter: Parameter<Element>)
        -> AnyParameterDecodingStrategy<Element, I> where Element: Decodable, Element: Encodable {
        TransformingParameterStrategy(strategy.strategy(for: parameter), using: transformer).typeErased
    }
}

public extension DecodingStrategy {
    /// Create a ``TransformingStrategy`` that mediates between this ``DecodingStrategy``
    /// and a parent with input type `I`.
    func transformed<I>(_ transformer: @escaping (I) throws -> Self.Input) -> TransformingStrategy<Self, I> {
        TransformingStrategy(self, using: transformer)
    }
}


// MARK: Implementations
