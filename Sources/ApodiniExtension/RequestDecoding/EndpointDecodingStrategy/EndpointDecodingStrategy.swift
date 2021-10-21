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


// MARK: EndpointDecodingStrategy

/// A strategy describing how a certain Apodini `EndpointParameter` can be decoded from
/// a fixed ``Input`` type.
///
/// This type is very similar to a ``DecodingStrategy``, except it works on a different `parameter`
/// type. You can obtain a ``DecodingStrategy`` from an ``EndpointDecodingStrategy`` by
/// applying it to an Apodini `Endpoint` using ``EndpointDecodingStrategy/applied(to:)``.
public protocol EndpointDecodingStrategy {
    /// The type which the ``ParameterDecodingStrategy``s returned by ``strategy(for:)``
    /// take as an input for ``ParameterDecodingStrategy/decode(from:)``.
    associatedtype Input = Data
    
    /// The actual strategy for determining a suitable ``ParameterDecodingStrategy`` for the
    /// given `parameter`.
    ///
    /// - Note: Due to the nature of `EndpointParameter` the `Element` is of a different type
    /// than the one of ``DecodingStrategy/strategy(for:)`` if the Apodini `Parameter` has
    /// an `Optional` type. Thus, the ``AnyParameterDecodingStrategy`` returned by this function
    /// might encounter the case that it finds a `nil` value where `Element` is not an `Optional`. In that
    /// case the ``ParameterDecodingStrategy/decode(from:)`` should throw an
    /// `DecodingError.valueNotFound`.
    func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Input>
}


// MARK: DecodingStrategy Conversion

extension EndpointDecodingStrategy {
    /// Create a ``DecodingStrategy`` from this ``EndpointDecodingStrategy`` by providing an
    /// `endpoint` that can be used to translate between the different parameter types.
    ///
    /// - Warning: The given `endpoint` must be the one that the resulting ``DecodingStrategy`` is
    /// going to be used on, otherwise evaluating the ``DecodingStrategy/strategy(for:)`` might result
    /// in a runtime crash.
    public func applied(to endpoint: AnyEndpoint) -> AnyDecodingStrategy<Input> {
        EndpointParameterBasedDecodingStrategy(self, on: endpoint).typeErased
    }
}


private struct EndpointParameterBasedDecodingStrategy<S: EndpointDecodingStrategy>: DecodingStrategy {
    private let strategy: S
    
    private let endpointParameters: [UUID: AnyEndpointParameter]
    
    init(_ strategy: S, on endpoint: AnyEndpoint) {
        self.strategy = strategy
        self.endpointParameters = endpoint[EndpointParametersById.self].parameters
    }
    
    func strategy<Element: Decodable>(for parameter: Parameter<Element>) -> AnyParameterDecodingStrategy<Element, S.Input> {
        guard let parameter = endpointParameters[parameter.id] as? CanCallEndpointParameterDecodingStrategy else {
            fatalError("Couldn't find matching 'EndpointParameter' with id \(parameter.id) while determining 'DecodingStrategy'.")
        }
        
        return parameter.call(strategy)
    }
}

private protocol CanCallEndpointParameterDecodingStrategy {
    func call<S: EndpointDecodingStrategy, Element: Decodable, Input>(_ strategy: S) -> AnyParameterDecodingStrategy<Element, Input>
}

extension EndpointParameter: CanCallEndpointParameterDecodingStrategy {
    func call<S, V, I>(_ strategy: S) -> AnyParameterDecodingStrategy<V, I> where S: EndpointDecodingStrategy, V: Decodable {
        let baseStrategy = strategy.strategy(for: self)
        if nilIsValidValue { // V == Optional<Type>
            if let typedStrategy = OptionalWrappingStrategy(baseStrategy: baseStrategy).typeErased as? AnyParameterDecodingStrategy<V, I> {
                return typedStrategy
            }
            fatalError("Internal logic of 'EndpointParameter.call(_:)' is broken: wrong type in nil case.")
        } else { // V == Type
            if let typedStrategy = baseStrategy as? AnyParameterDecodingStrategy<V, I> {
                return typedStrategy
            }
            fatalError("Internal logic of 'EndpointParameter.call(_:)' is broken: wrong type in base case.")
        }
    }
}

private struct OptionalWrappingStrategy<P: ParameterDecodingStrategy>: ParameterDecodingStrategy {
    let baseStrategy: P
    
    func decode(from input: P.Input) throws -> P.Element? {
        do {
            return .some(try baseStrategy.decode(from: input))
        } catch DecodingError.valueNotFound(_, _) {
            return .none
        }
    }
}


// MARK: AnyEndpointDecodingStrategy

public extension EndpointDecodingStrategy {
    /// Erases the type from this ``EndpointDecodingStrategy``.
    var typeErased: AnyEndpointDecodingStrategy<Input> {
        AnyEndpointDecodingStrategy(self)
    }
}

/// A type-erased wrapper around any ``EndpointDecodingStrategy``.
public struct AnyEndpointDecodingStrategy<I>: EndpointDecodingStrategy {
    private let caller: EndpointDecodingStrategyCaller
    
    init<S: EndpointDecodingStrategy>(_ strategy: S) where S.Input == I {
        self.caller = SomeEndpointDecodingStrategyCaller(strategy: strategy)
    }
    
    public func strategy<Element>(for parameter: EndpointParameter<Element>)
        -> AnyParameterDecodingStrategy<Element, I> where Element: Decodable, Element: Encodable {
        caller.call(with: parameter)
    }
}

private protocol EndpointDecodingStrategyCaller {
    func call<E: Decodable, I>(with parameter: EndpointParameter<E>) -> AnyParameterDecodingStrategy<E, I>
}

private struct SomeEndpointDecodingStrategyCaller<S: EndpointDecodingStrategy>: EndpointDecodingStrategyCaller {
    let strategy: S
    
    func call<E: Decodable, I>(with parameter: EndpointParameter<E>) -> AnyParameterDecodingStrategy<E, I> {
        guard let parameterStrategy = strategy.strategy(for: parameter) as? AnyParameterDecodingStrategy<E, I> else {
            fatalError("'SomeEndpointDecodingStrategyCaller' was used with wrong input type (\(I.self) instead of \(S.Input.self))")
        }
        return parameterStrategy
    }
}


// MARK: TransformingStrategy

/// A ``EndpointDecodingStrategy`` that forms a transition between a wrapped ``EndpointDecodingStrategy`` `S`
/// and a parent ``EndpointDecodingStrategy`` with ``EndpointDecodingStrategy/Input`` type `I`.
///
/// This strategy allows for reuse of ``EndpointDecodingStrategy`` with a more basic ``EndpointDecodingStrategy/Input`` than
/// the one you are actually using. E.g. many of the predefined strategies have input type `Data`.
/// If your input type is a complete request, you can probably reuse those predefined strategies by extracting the body
/// from the request.
public struct TransformingEndpointStrategy<S: EndpointDecodingStrategy, I>: EndpointDecodingStrategy {
    private let transformer: (I) throws -> S.Input
    private let strategy: S
    
    public init(_ strategy: S, using transformer: @escaping (I) throws -> S.Input) {
        self.strategy = strategy
        self.transformer = transformer
    }
    
    public func strategy<Element: Codable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, I> {
        TransformingParameterStrategy(strategy.strategy(for: parameter), using: transformer).typeErased
    }
}

public extension EndpointDecodingStrategy {
    /// Create a ``TransformingEndpointStrategy`` that mediates between this ``EndpointDecodingStrategy``
    /// and a parent with input type `I`.
    func transformed<I>(_ transformer: @escaping (I) throws -> Self.Input) -> TransformingEndpointStrategy<Self, I> {
        TransformingEndpointStrategy(self, using: transformer)
    }
}
