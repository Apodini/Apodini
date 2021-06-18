//
//  Set+Information.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import Foundation


extension Set where Element == AnyInformation {
    /// Returns an `Information` instance based on the `Information` type passed in
    /// - Parameter key: The `Information` type that is requested
    /// - Returns: An `Information.Value` instance if one an `Information` instance of the type exists..
    public subscript<I: Information>(_ key: I.Type = I.self) -> I.Value? {
        value(associatedWith: key)
    }
    
    /// Returns the `String` value assoicated with the `key`
    /// - Parameter key: The information `key` that the value should be retrieved from.
    /// - Returns: The value associated with the `key`
    public subscript(_ key: String) -> String? {
        value(associatedWith: key)
    }
    
    
    /// Returns an `Information` instance based on the `Information` type passed in
    /// - Parameter key: The `Information` type that is requested
    /// - Returns: An `Information.Value` instance if one an `Information` instance of the type exists.
    public func value<I: Information>(associatedWith key: I.Type = I.self) -> I.Value? {
        first(where: { $0.key == I.key })?.value as? I.Value
    }
    
    /// Returns the `String` value assoicated with the `key`
    /// - Parameter key: The information `key` that the value should be retrieved from.
    /// - Returns: The value associated with the `key`
    public func value(associatedWith key: String) -> String? {
        first(where: { $0.key == key })?.rawValue
    }
}
