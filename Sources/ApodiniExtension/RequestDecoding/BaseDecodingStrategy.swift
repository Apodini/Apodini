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

public protocol BaseDecodingStrategy: DecodingStrategy, EndpointDecodingStrategy {
    associatedtype Input = Data
    
    func strategy<Element: Decodable, I: Identifiable>(for parameter: I) -> AnyParameterDecodingStrategy<Element, Input> where I.ID == UUID
}


// MARK: DecodingStrategy / EndpointDecodingStrategy Conformance

extension BaseDecodingStrategy {
    public func strategy<Element>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Input> where Element : Decodable, Element : Encodable {
        self.strategy(parameter)
    }
    
    public func strategy<Element>(for parameter: Parameter<Element>) -> AnyParameterDecodingStrategy<Element, Input> where Element : Decodable, Element : Encodable {
        self.strategy(parameter)
    }
    
    private func strategy<I: Identifiable, Element: Decodable>(_ parameter: I) -> AnyParameterDecodingStrategy<Element, Input> where I.ID == UUID {
        self.strategy(for: parameter)
    }
}


// MARK: AnyBaseDecodingStrategy

public struct AnyBaseDecodingStrategy<Input>: BaseDecodingStrategy {
    private let caller: BaseDecodingStrategyCaller
    
    
    init<S: BaseDecodingStrategy>(_ strategy: S) where S.Input == Input {
        self.caller = SomeBaseDecodingStrategyCaller(strategy: strategy)
    }
    
    public func strategy<Element, I>(for parameter: I) -> AnyParameterDecodingStrategy<Element, Data> where Element : Decodable, I : Identifiable, I.ID == UUID {
        caller.call(with: parameter)
    }
}

private protocol BaseDecodingStrategyCaller {
    func call<E: Decodable, I, ID: Identifiable>(with parameter: ID) -> AnyParameterDecodingStrategy<E, I> where ID.ID == UUID
}

private struct SomeBaseDecodingStrategyCaller<S: BaseDecodingStrategy>: BaseDecodingStrategyCaller {
    let strategy: S
    
    func call<E: Decodable, I, ID: Identifiable>(with parameter: ID) -> AnyParameterDecodingStrategy<E, I> where ID.ID == UUID {
        let untypedParameterStrategy: AnyParameterDecodingStrategy<E, S.Input> = strategy.strategy(for: parameter)
        guard let parameterStrategy = untypedParameterStrategy as? AnyParameterDecodingStrategy<E, I> else {
            fatalError("'SomeBaseDecodingStrategyCaller' was used with wrong input type (\(I.self) instead of \(S.Input.self))")
        }
        return parameterStrategy
    }
}


// MARK: TransformingStrategy

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


// MARK: Implementations

public struct AllIdentityStrategy: BaseDecodingStrategy {
    private let decoder: AnyDecoder
    
    public init(_ decoder: AnyDecoder) {
        self.decoder = decoder
    }
    
    public func strategy<Element, I>(for parameter: I) -> AnyParameterDecodingStrategy<Element, Data> where Element : Decodable, I: Identifiable {
        PlainPatternStrategy<IdentityPattern<Element>>(decoder).typeErased
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
