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
public struct Properties: Property, InstanceCodable {
    internal var elements: [String: Property]
    
    internal var namingStrategy: ([String]) -> String? = Self.defaultNamingStrategy
    
    /// Create a new `Properties` from the given `elements`
    /// - Parameters:
    ///     - namingStrategy: The `namingStrategy` is called when the framework decides to interact with one of
    ///         the `Properties`'s elements. By default it assumes the key of this element to be the
    ///         desired name of the element.
    ///         This behavior can be changed by providing a different `namingStrategy`. E.g. to expose an internal
    ///         `@Parameter` using the name that was given to the wrapping `Properties` the
    ///         `namingStrategy` would be to return `names[names.count-2]`.
    /// - Complexity: O(1)
    public init(wrappedValue elements: [String: Property], namingStrategy: @escaping ([String]) -> String? = Self.defaultNamingStrategy) {
        self.elements = elements
        self.namingStrategy = namingStrategy
    }
    
    /// Create a new `Properties` from the given `elements`
    /// - Parameters:
    ///     - namingStrategy: The `namingStrategy` is called when the framework decides to interact with one of
    ///         the `Properties`'s elements. By default it assumes the key of this element to be the
    ///         desired name of the element.
    ///         This behavior can be changed by providing a different `namingStrategy`. E.g. to expose an internal
    ///         `@Parameter` using the name that was given to the wrapping `Properties` the
    ///         `namingStrategy` would be to return `names[names.count-2]`.
    /// - Complexity: O(n)
    public init(_ elements: [(String, Property)], namingStrategy: @escaping ([String]) -> String? = Self.defaultNamingStrategy) {
        self.elements = [:]
        for element in elements {
            self.elements[element.0] = element.1
        }
        self.namingStrategy = namingStrategy
    }
    
    subscript<T>(dynamicMember name: String) -> T? {
        self.elements[name] as? T
    }
    
    /// The named elements managed by this object.
    public var wrappedValue: [String: Property] {
        self.elements
    }
    
    public static var defaultNamingStrategy: ([String]) -> String? = { names in
        names.last
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
