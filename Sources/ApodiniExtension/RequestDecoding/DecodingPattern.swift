//
//  DecodingPattern.swift
//  
//
//  Created by Max Obermeier on 24.06.21.
//

import Foundation
import Apodini
import ApodiniUtils

// MARK: DecodingPattern

public protocol DecodingPattern: Decodable {
    associatedtype Element: Decodable
    
    var value: Element { get }
}


// MARK: Implementations

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

internal let namedChildStrategyFieldName = ThreadSpecificVariable<FieldName>()

internal class FieldName {
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
