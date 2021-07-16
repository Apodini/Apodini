//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
