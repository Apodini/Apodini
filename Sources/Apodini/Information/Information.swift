//
//  Information.swift
//  
//
//  Created by Paul Schmiedmayer on 5/26/21.
//

import Foundation


/// Information describes additional metadata that can be attached to a `Response` or can be found in the `ConnectionContext` in the `@Environment` of a `Handler`.
@dynamicMemberLookup
public protocol Information: RawRepresentable where RawValue == String {
    /// The value associated with the type implementing `Information`
    associatedtype Value
    
    
    /// A key identifying the type implementing `Information`
    static var key: String { get }
    
    
    /// The value associated with the type implementing `Information`
    var value: Value { get }
    
    
    /// Creeate an `Information` based on a value
    /// - Parameters:
    ///   - value: The `Information` value
    init(_ value: Value)
    
    
    /// Enables developeers to direcly access properties of the `Value` using the `Information`
    subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T { get }
}


extension Information {
    /// Enables developeers to direcly access properties of the `Value` using the `Information`
    public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
        value[keyPath: keyPath]
    }
}
