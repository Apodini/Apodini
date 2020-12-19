//
//  Dynamics.swift
//  
//
//  Created by Max Obermeier on 10.12.20.
//

import Foundation

/// Dynamics provides same functionality as `DynamicProperty`, but for elements that are only known
/// at statup and not compile-time. That is, `Dynamics` stores named elements and makes them
/// discoverable to the Apodini runtime framework.  This can be used to e.g. delay the decision, which
/// `Parameter`s are exported to startup-time
@dynamicMemberLookup
@propertyWrapper
public struct Dynamics<Element> {
    internal var elements: [String: Element]
    
    /// Create a new `Dynamics` from the given `elements`
    /// - Complexity: O(1)
    public init(wrappedValue elements: [String: Element]) {
        self.elements = elements
    }
    
    /// Create a new `Dynamics` from the given `elements`
    /// - Complexity: O(n)
    public init(_ elements: [(String, Element)]) {
        self.elements = [:]
        for element in elements {
            self.elements[element.0] = element.1
        }
    }
    
    subscript<T>(dynamicMember name: String) -> T? {
        self.elements[name] as? T
    }
    
    public var wrappedValue: [String: Element] {
        self.elements
    }
}

extension Dynamics: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    
    public typealias Value = Element
    
    /// Create a new `Dynamics` from the given `elements`
    /// - Complexity: O(n)
    public init(dictionaryLiteral elements: (String, Element)...) {
        self.elements = [:]
        for element in elements {
            self.elements[element.0] = element.1
        }
    }
}

extension Dynamics: Collection {
    public typealias Index = Dictionary<String, Element>.Index
    public typealias Element = (String, Element)
    
    public var startIndex: Dictionary<String, Element>.Index {
        self.elements.startIndex
    }
    
    public var endIndex: Dictionary<String, Element>.Index {
        self.elements.endIndex
    }
    
    public func index(after index: Dictionary<String, Element>.Index) -> Dictionary<String, Element>.Index {
        self.elements.index(after: index)
    }
    
    public subscript(position: Dictionary<String, Element>.Index) -> (String, Element) {
        self.elements[position]
    }
}

public extension Dynamics {
    /// This function provides a  copy of the `Dynamics` which only contains elements that
    /// conform to type `T`
    /// - Complexity: O(n)
    func typed<T>(_ type: T.Type = T.self) -> Dynamics<T> {
        Dynamics<T>(self.compactMap { key, value in
            if let typedValue = value as? T {
                return (key, typedValue)
            }
            return nil
        })
    }
}

public extension Dynamics {
    /// This function unwraps the `wrappedValue` from the `element`'s `Parameter`
    static func unwrap<T>(_ element: (String, Parameter<T>)) -> (String, T) {
        (element.0, element.1.wrappedValue)
    }
}
