//
//  BaseDecodingStrategy.swift
//  
//
//  Created by Max Obermeier on 28.06.21.
//

import Foundation
import Apodini
import ApodiniUtils

// MARK: BaseDecodingStrategy

/// A strategy describing how a certain Apodini parameter can be decoded from
/// a fixed ``Input`` type. The parameter is solely characterized by its `id`.
public protocol BaseDecodingStrategy: DecodingStrategy, EndpointDecodingStrategy {
    /// The type which the ``ParameterDecodingStrategy``s returned by ``strategy(for:)-9lwgq``
    /// take as an input for ``ParameterDecodingStrategy/decode(from:)``.
    associatedtype Input = Data
    
    /// The actual strategy for determining a suitable ``ParameterDecodingStrategy`` for the
    /// given `parameter`.
    func strategy<Element: Decodable, I: Identifiable>(for parameter: I)
        -> AnyParameterDecodingStrategy<Element, Input> where I.ID == UUID
}


// MARK: DecodingStrategy / EndpointDecodingStrategy Conformance

extension BaseDecodingStrategy {
    /// The default implementation for ``DecodingStrategy/strategy(for:)`` which calls
    /// ``BaseDecodingStrategy/strategy(for:)-9lwgq`` with the `parameter`'s `id`.
    public func strategy<Element>(for parameter: EndpointParameter<Element>)
        -> AnyParameterDecodingStrategy<Element, Input> where Element: Decodable, Element: Encodable {
        self.strategy(parameter)
    }
    
    /// The default implementation for ``EndpointDecodingStrategy/strategy(for:)`` which calls
    /// ``BaseDecodingStrategy/strategy(for:)-9lwgq`` with the `parameter`'s `id`.
    public func strategy<Element>(for parameter: Parameter<Element>)
        -> AnyParameterDecodingStrategy<Element, Input> where Element: Decodable, Element: Encodable {
        self.strategy(parameter)
    }
    
    private func strategy<I: Identifiable, Element: Decodable>(_ parameter: I)
        -> AnyParameterDecodingStrategy<Element, Input> where I.ID == UUID {
        self.strategy(for: parameter)
    }
}


// MARK: AnyBaseDecodingStrategy

public extension BaseDecodingStrategy {
    /// Erases the type from this ``BaseDecodingStrategy``.
    var typeErased: AnyBaseDecodingStrategy<Input> {
        AnyBaseDecodingStrategy(self)
    }
}

/// A type-erased wrapper around any ``BaseDecodingStrategy``.
public struct AnyBaseDecodingStrategy<Input>: BaseDecodingStrategy {
    private let caller: BaseDecodingStrategyCaller
    
    
    init<S: BaseDecodingStrategy>(_ strategy: S) where S.Input == Input {
        self.caller = SomeBaseDecodingStrategyCaller(strategy: strategy)
    }
    
    public func strategy<Element, I>(for parameter: I)
        -> AnyParameterDecodingStrategy<Element, Data> where Element: Decodable, I: Identifiable, I.ID == UUID {
        caller.call(with: parameter)
    }
}

private protocol BaseDecodingStrategyCaller {
    func call<E: Decodable, I, ID: Identifiable>(with parameter: ID)
        -> AnyParameterDecodingStrategy<E, I> where ID.ID == UUID
}

private struct SomeBaseDecodingStrategyCaller<S: BaseDecodingStrategy>: BaseDecodingStrategyCaller {
    let strategy: S
    
    func call<E: Decodable, I, ID: Identifiable>(with parameter: ID)
        -> AnyParameterDecodingStrategy<E, I> where ID.ID == UUID {
        let untypedParameterStrategy: AnyParameterDecodingStrategy<E, S.Input> = strategy.strategy(for: parameter)
        guard let parameterStrategy = untypedParameterStrategy as? AnyParameterDecodingStrategy<E, I> else {
            fatalError("'SomeBaseDecodingStrategyCaller' was used with wrong input type (\(I.self) instead of \(S.Input.self))")
        }
        return parameterStrategy
    }
}


// MARK: TransformingStrategy

/// A ``BaseDecodingStrategy`` that forms a transition between a wrapped ``BaseDecodingStrategy`` `S`
/// and a parent ``BaseDecodingStrategy`` with ``BaseDecodingStrategy/Input`` type `I`.
///
/// This strategy allows for reuse of ``BaseDecodingStrategy`` with a more basic ``BaseDecodingStrategy/Input`` than
/// the one you are acutally using. E.g. many of the predefined strategies have input type `Data`.
/// If your input type is a complete request, you can probably reuse those predefined strategies by extracting the body
/// from the request.
public struct TransformingBaseStrategy<S: BaseDecodingStrategy, Input>: BaseDecodingStrategy {
    private let transformer: (Input) throws -> S.Input
    private let strategy: S
    
    init(_ strategy: S, using transformer: @escaping (Input) throws -> S.Input) {
        self.strategy = strategy
        self.transformer = transformer
    }
    
    public func strategy<Element, I>(for parameter: I)
        -> AnyParameterDecodingStrategy<Element, Input> where Element: Decodable, I: Identifiable, I.ID == UUID {
        TransformingParameterStrategy(strategy.strategy(for: parameter), using: transformer).typeErased
    }
}

public extension BaseDecodingStrategy {
    /// Create a ``TransformingBaseStrategy`` that mediates between this ``BaseDecodingStrategy``
    /// and a parent with input type `I`.
    func transformed<I>(_ transformer: @escaping (I) throws -> Self.Input) -> TransformingBaseStrategy<Self, I> {
        TransformingBaseStrategy(self, using: transformer)
    }
}


// MARK: Implementations

/// An ``BaseDecodingStrategy`` that uses a certain `AnyDecoder` to decode each
/// parameter from the given `Data`.
///
/// The strategy expects the `Data` to hold the `Element` at its base.
///
/// E.g. for `Element` being `String`, the following JSON would be a valid input:
///
/// ```json
/// "Max"
/// ```
///
/// - Note: Usage of this strategy only really makes sense if there is only one parameter
/// to be decoded from the given `Data`.
public struct AllIdentityStrategy: BaseDecodingStrategy {
    private let decoder: AnyDecoder
    
    public init(_ decoder: AnyDecoder) {
        self.decoder = decoder
    }
    
    public func strategy<Element, I>(for parameter: I)
        -> AnyParameterDecodingStrategy<Element, Data> where Element: Decodable, I: Identifiable {
        PlainPatternStrategy<IdentityPattern<Element>>(decoder).typeErased
    }
}

/// A ``BaseDecodingStrategy`` that chooses a different ``ParameterDecodingStrategy`` based
/// on the `parameter`'s `id`.
public struct IdentifierBasedStrategy<Input>: BaseDecodingStrategy {
    private var strategies = [UUID: Any]()
    
    /// Create an empty ``IdentifierBasedStrategy`` that is still to be filled with the acutal
    /// strategies using ``IdentifierBasedStrategy/with(strategy:for:)``.
    ///
    /// - Warning: If not filled with a strategy for each relevant parameter, this strategy crashes on runtime!
    public init() {}
    
    public func strategy<Element, I>(for parameter: I)
        -> AnyParameterDecodingStrategy<Element, Input> where Element: Decodable, I: Identifiable, I.ID == UUID {
        guard let strategy = strategies[parameter.id] as? AnyParameterDecodingStrategy<Element, Input> else {
            fatalError("'IdentifierBasedStrategy' is missing strategy for parameter with id \(parameter.id)!")
        }
        return strategy
    }
    
    /// Add a certain `strategy` to be used for decoding `parameter`.
    public func with<P: ParameterDecodingStrategy, I: Identifiable>(strategy: P, for parameter: I)
        -> Self where I.ID == UUID, P.Input == Input {
        var selfCopy = self
        selfCopy.strategies[parameter.id] = strategy.typeErased
        return selfCopy
    }
}
