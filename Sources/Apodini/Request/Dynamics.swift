//
//  Dynamics.swift
//  
//
//  Created by Max Obermeier on 10.12.20.
//

import Foundation

public struct Dynamics {

    internal var elements: [String: Any]
    
    init(_ elements: (name: String, Any)...) {
        self.elements = [:]
        for e in elements {
            self.elements[e.name] = e.1
        }
    }
    
    subscript<T>(name: String) -> T? {
        self.elements[name] as? T
    }
    
    
}
