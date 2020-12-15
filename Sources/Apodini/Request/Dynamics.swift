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


//public struct Dynamics<E> {
//
//    internal var elements: [String: E]
//
//    init(_ elements: (name: String, E)...) {
//        self.elements = [:]
//        for element in elements {
//            self.elements[element.name] = element.1
//        }
//    }
//
//    subscript<T>(name: String) -> T? {
//        self.elements[name] as? T
//    }
//}
//
//extension Dynamics: Collection {
//
//    public typealias Element = (name: String, E)
//
//    public var startIndex: Dictionary<String, E>.Index {
//        self.elements.startIndex
//    }
//
//    public var endIndex: Dictionary<String, E>.Index {
//        self.elements.endIndex
//    }
//
//    public subscript(position: Dictionary<String, E>.Index) -> (name: String, E) {
//        get {
//            let elem = self.elements[position]
//            return (name: elem.key, elem.value)
//        }
//    }
//
//    public func index(after i: Dictionary<String, E>.Index) -> Dictionary<String, E>.Index {
//        elements.index(after: i)
//    }
//}
