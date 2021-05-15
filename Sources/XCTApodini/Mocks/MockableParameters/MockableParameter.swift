//
//  MockableParameter.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

#if DEBUG
import Apodini


public protocol MockableParameter {
    var id: String { get }
    
    
    func getValue<Type: Decodable>(for parameter: EndpointParameter<Type>) -> Type??
}
#endif
