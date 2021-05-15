//
//  NamedParameter.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

#if DEBUG
import Apodini


public struct NamedParameter<Value: Decodable>: MockableParameter {
    let name: String
    let unnamedParameter: UnnamedParameter<Value>
    
    
    public var id: String {
        "\(ObjectIdentifier(Value.self)):\(name)"
    }
    
    
    public init(_ name: String, value: Value?) {
        self.name = name
        self.unnamedParameter = UnnamedParameter(value)
    }
    
    
    public func getValue<Type: Decodable>(for parameter: EndpointParameter<Type>) -> Type?? {
        guard parameter.name == self.name else {
            return nil
        }
        
        return unnamedParameter.getValue(for: parameter)
    }
}
#endif
