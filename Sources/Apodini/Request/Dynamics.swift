//
//  Dynamics.swift
//  
//
//  Created by Max Obermeier on 10.12.20.
//

import Foundation

/// Dynamics provides same functionality as DynamicProperty, but for elements that are only known
/// at statup and not compile-time
@dynamicMemberLookup
public struct Dynamics {
    internal var elements: [String: Any]
    
    init(_ elements: [String: Any]) {
        self.elements = elements
    }
    
    subscript<T>(dynamicMember name: String) -> T? {
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

extension Dynamics {
    func typed<T>(_ type: T.Type) -> [(String, T)] {
        self.elements.compactMap { (key, value) in
            if let typedValue = value as? T {
                return (key, typedValue)
            }
            return nil
        }
    }
    
    func typed<T>() -> [(String, T)] {
        self.typed(T.self)
    }
}

extension Dynamics {
    static func unwrap<T>(_ element: (String, Parameter<T>)) -> (String, T) {
        (element.0, element.1.wrappedValue)
    }
}
