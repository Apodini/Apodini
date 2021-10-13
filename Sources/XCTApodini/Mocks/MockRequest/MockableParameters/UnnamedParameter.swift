//
//  UnnamedParameter.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

import Apodini


public struct UnnamedParameter<Value: Decodable>: MockableParameter {
    private let value: Value?
    private let type: ParameterType?
    
    
    public var description: String {
        "\(type?.description ?? "No Type") = \(String(describing: value))"
    }
    
    public var id: String {
        "\(ObjectIdentifier(Value.self)):\(Int.random(in: Int.min...Int.max))"
    }
    
    
    public init(_ value: Value?, type: ParameterType? = nil) {
        self.value = value
        self.type = type
    }
    
    
    public func getValue<Type: Decodable>(for parameter: EndpointParameter<Type>) -> Type? {
        guard Type.self == Value.self else {
            return nil
        }
        
        if let type = type, type != parameter.parameterType {
            return nil
        }

        
        guard let casted = value as? Type else {
            fatalError("MockExporter: Could not cast value \(String(describing: value)) to type \(Type.self) for '\(parameter.description)'")
        }
        
        return casted
    }
}
