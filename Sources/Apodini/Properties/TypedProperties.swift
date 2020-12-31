//
//  TypedProperties.swift
//  
//
//  Created by Paul Schmiedmayer on 12/29/20.
//

import Foundation

/// A typed version of an `@Properties` instance.
public struct TypedProperties<P: Property>: Property {
    internal var elements: [String: P]
    
    /// Create a new `TypedProperties` from the given `elements`
    /// - Complexity: O(n)
    internal init(_ elements: [(String, P)]) {
        self.elements = [:]
        for element in elements {
            self.elements[element.0] = element.1
        }
    }
    
    
    public subscript(_ name: String) -> P? {
        self.elements[name]
    }
}

extension TypedProperties: Collection {
    public typealias Index = Dictionary<String, P>.Index
    public typealias Element = (String, P)
    
    public var startIndex: Dictionary<String, P>.Index {
        self.elements.startIndex
    }
    
    public var endIndex: Dictionary<String, P>.Index {
        self.elements.endIndex
    }
    
    public func index(after index: Dictionary<String, P>.Index) -> Dictionary<String, P>.Index {
        self.elements.index(after: index)
    }
    
    public subscript(position: Dictionary<String, P>.Index) -> (String, P) {
        self.elements[position]
    }
}

public extension Properties {
    /// This function provides a  copy of the `Properties` which only contains elements that
    /// conform to type `P`
    /// - Complexity: O(n)
    func typed<P: Property>(_ type: P.Type = P.self) -> TypedProperties<P> {
        TypedProperties(self.compactMap { key, value in
            if let typedValue = value as? P {
                return (key, typedValue)
            }
            return nil
        })
    }
}
