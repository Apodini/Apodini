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

public protocol ParameterDecodingStrategy {
    associatedtype Element: Decodable
    associatedtype Input = Data
    
    func decode(from input: Input) throws -> Element
}


// MARK: AnyParameterDecodingStrategy

public extension ParameterDecodingStrategy {
    var typeErased: AnyParameterDecodingStrategy<Element, Input> {
        AnyParameterDecodingStrategy(self)
    }
}

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


// MARK: Implementations


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
