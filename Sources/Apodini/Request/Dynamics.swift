//
//  Dynamics.swift
//  
//
//  Created by Max Obermeier on 10.12.20.
//

import Foundation

/// Dynamics provides same functionality as DynamicProperty, but for elements that are only known
/// at statup and not compile-time
public struct Dynamics {
    internal var elements: [String: Any]
    
    init(_ elements: [String: Any]) {
        self.elements = elements
    }
    
    subscript<T>(name: String) -> T? {
        self.elements[name] as? T
    }
}

extension Dynamics: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    
    public typealias Value = Any
    
    public init(dictionaryLiteral elements: (String, Any)...) {
        self.elements = [:]
        for element in elements {
            self.elements[element.0] = element.1
        }
    }
}
