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

public protocol DecodingStrategy {
    associatedtype Input = Data
    
    func strategy<Element: Decodable>(for parameter: Parameter<Element>) -> AnyParameterDecodingStrategy<Element, Input>
}


// MARK: AnyDecodingStrategy

public extension DecodingStrategy {
    var typeErased: AnyDecodingStrategy<Input> {
        AnyDecodingStrategy(self)
    }
}

public struct AnyDecodingStrategy<I>: DecodingStrategy {
    private let caller: DecodingStrategyCaller
    
    
    init<S: DecodingStrategy>(_ strategy: S) where S.Input == I {
        self.caller = SomeDecodingStrategyCaller(strategy: strategy)
    }
    
    
    public func strategy<Element>(for parameter: Parameter<Element>) -> AnyParameterDecodingStrategy<Element, I> where Element : Decodable, Element : Encodable {
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


// MARK: Implementations
