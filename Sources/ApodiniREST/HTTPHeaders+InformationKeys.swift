//
//  HTTPHeaders+Context.swift
//  
//
//  Created by Paul Schmiedmayer on 5/26/21.
//

import Apodini
import Vapor


extension Vapor.HTTPHeaders {
    init(_ information: [InformationKey: String]) {
        self.init()
        for (name, value) in information {
            self.add(name: name.rawValue, value: value)
        }
    }
}
