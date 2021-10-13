//
//  NamedParameter.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

import Apodini


public struct NamedParameter<Value: Decodable>: MockableParameter {
    private let name: String
    private let unnamedParameter: UnnamedParameter<Value>
    
    
    public var description: String {
        "\(name): \(unnamedParameter.description)"
    }
    
    public var id: String {
        "\(ObjectIdentifier(Value.self)):\(name)"
    }
    
    
    public init(_ name: String, value: Value?, type: ParameterType? = nil) {
        self.name = name
        self.unnamedParameter = UnnamedParameter(value, type: type)
    }
    
    
    public func getValue<Type: Decodable>(for parameter: EndpointParameter<Type>) -> Type? {
        guard parameter.name == self.name else {
            return nil
        }
        
        return unnamedParameter.getValue(for: parameter)
    }
}
