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
    public init(_ information: InformationSet) {
        self.init()

        for (header, value) in information
            .compactMap({ $0 as? HTTPHeaderInformationClass })
            .map({ $0.entry }) {
            self.add(name: header, value: value)
        }
    }
}
