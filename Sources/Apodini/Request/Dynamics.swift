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
    
    init(_ elements: (name: String, Any)...) {
        self.elements = [:]
        for element in elements {
            self.elements[element.name] = element.1
        }
    }
    
    subscript<T>(name: String) -> T? {
        self.elements[name] as? T
    }
}
