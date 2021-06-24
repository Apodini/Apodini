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
