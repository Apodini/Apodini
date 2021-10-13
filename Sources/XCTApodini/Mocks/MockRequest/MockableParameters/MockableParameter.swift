//
//  MockableParameter.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

import Apodini


public protocol MockableParameter: CustomStringConvertible {
    var id: String { get }
    
    
    func getValue<Type: Decodable>(for parameter: EndpointParameter<Type>) -> Type?
}
