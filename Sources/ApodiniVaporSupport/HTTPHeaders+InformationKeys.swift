//
//  HTTPHeaders+Context.swift
//  
//
//  Created by Paul Schmiedmayer on 5/26/21.
//

import Apodini
import Vapor


extension Vapor.HTTPHeaders {
    /// Creates a `Vapor``HTTPHeaders` instance based on an `Apodini` `Information` array.
    /// - Parameter information: The `Apodini` `Information` array that should be transformed in a `Vapor``HTTPHeaders` instance
    public init(_ information: Set<AnyInformation>) {
        self.init()
        for (key, value) in information.map({ ($0.key, $0.rawValue) }) {
            self.add(name: key, value: value)
        }
    }
}
