//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import Foundation


extension Set where Element == Information {
    /// Returns an `Information` instance based on the `InformationKey` passed in
    /// - Parameter key: The `InformationKey` that is associated with the `Information` requested
    /// - Returns: An `Information` instance if one for the `InformationKey` exists.
    public subscript(_ key: InformationKey) -> Information? {
        informationWithKey(key)
    }
    
    /// Returns an `Information` instance based on the `InformationKey` passed in
    /// - Parameter key: The `InformationKey` that is associated with the `Information` requested
    /// - Returns: An `Information` instance if one for the `InformationKey` exists.
    public func informationWithKey(_ key: InformationKey) -> Information? {
        first(where: { $0.key == key })
    }
}
