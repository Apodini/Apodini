//
//  Properties.swift
//  
//
//  Created by Max Obermeier on 10.12.20.
//

import Foundation

/// Properties provides same functionality as `DynamicProperty`, but for elements that are only known
/// at statup and not compile-time. That is, `Properties` stores named elements and makes the ones
/// conforming to `Property` discoverable to the Apodini runtime framework.
/// `Properties` can be used to e.g. delay the decision, which `Parameter`s are exported to startup-time.
@dynamicMemberLookup
@propertyWrapper
public struct Properties: Property {
    internal var elements: [String: Property]
    
    /// Create a new `Properties` from the given `elements`
    /// - Complexity: O(1)
    public init(wrappedValue elements: [String: Property]) {
        self.elements = elements
    }
    
    /// Create a new `Properties` from the given `elements`
    /// - Complexity: O(n)
    public init(_ elements: [(String, Property)]) {
        self.elements = [:]
        for element in elements {
            self.elements[element.0] = element.1
        }
    }
    
    subscript<T>(dynamicMember name: String) -> T? {
        self.elements[name] as? T
    }
    
    /// The named elements managed by this object.
    public var wrappedValue: [String: Property] {
        self.elements
    }
}

extension Properties: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    
    public typealias Value = Property
    
    /// Create a new `Properties` from the given `elements`
    /// - Complexity: O(n)
    public init(dictionaryLiteral elements: (String, Property)...) {
        self.elements = [:]
        for element in elements {
            self.elements[element.0] = element.1
        }
    }
}

extension Properties: Collection {
    public typealias Index = Dictionary<String, Property>.Index
    public typealias Element = (String, Property)
    
    public var startIndex: Index {
        self.elements.startIndex
    }
    
    public var endIndex: Index {
        self.elements.endIndex
    }
    
    public func index(after index: Index) -> Index {
        self.elements.index(after: index)
    }
    
    public subscript(position: Index) -> Element {
        self.elements[position]
    }
}

public extension Properties {
    /// This function unwraps the `wrappedValue` from the `element`'s `Parameter`
    static func unwrap<T>(_ element: (String, Parameter<T>)) -> (String, T) {
        (element.0, element.1.wrappedValue)
    }
}
