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

/// - Note: Only works with ``NamedChildPatternStrategy`` or ``IndexedNamedChildPatternStrategy``
public struct DynamicNamePattern<E: DecodingPattern>: DecodingPattern {
    public let value: E.Element
    
    public init(from decoder: Decoder) throws {
        guard let name = namedChildStrategyFieldName.currentValue?.name else {
            fatalError("DynamicNamePattern was used without setting field name prior to decoding!")
        }
        let container = try decoder.container(keyedBy: String.self)
        value = try container.decode(E.self, forKey: name).value
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


/// - Note: Only works with ``IndexedNamedChildPatternStrategy``
public struct DynamicIndexPattern<E: DecodingPattern>: DecodingPattern {
    public let value: E.Element
    
    public init(from decoder: Decoder) throws {
        guard let index = indexStrategyIndex.currentValue?.index else {
            fatalError("DynamicIndexPattern was used without setting index prior to decoding!")
        }
        var container = try decoder.unkeyedContainer()
        
        while container.currentIndex < index {
            _ = try container.decode(MockDecodable.self)
        }
        
        value = try container.decode(E.self).value
    }
    
    private struct MockDecodable: Decodable {
        init(from decoder: Decoder) throws { }
    }
}

internal let indexStrategyIndex = ThreadSpecificVariable<Index>()

internal class Index {
    var index: Int
    
    init(_ index: Int) {
        self.index = index
    }
}
