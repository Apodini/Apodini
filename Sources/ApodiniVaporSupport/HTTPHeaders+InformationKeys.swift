//
//  HTTPHeaders+Context.swift
//  
//
//  Created by Paul Schmiedmayer on 5/26/21.
//

import Apodini
import Vapor


extension Vapor.HTTPHeaders {
    public init(_ information: [Information]) {
        self.init()
        for (name, value) in information.map({ $0.keyValuePair }) {
            self.add(name: name, value: value)
        }
    }
}
