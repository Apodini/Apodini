//
//  UnnamedParameter.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

#if DEBUG
import Apodini


public struct UnnamedParameter<Value: Decodable>: MockableParameter {
    private let value: Value?
    
    
    public var id: String {
        "\(ObjectIdentifier(Value.self)):\(Int.random(in: Int.min...Int.max))"
    }
    
    
    public init(_ value: Value?) {
        self.value = value
    }
    
    
    public func getValue<Type: Decodable>(for parameter: EndpointParameter<Type>) -> Type?? {
        guard Type.self == Value.self else {
            return nil
        }
        
        guard let unwrappedValue = value else {
            return .some(.none) // Explict null value that as passed in from the consumer (developer writing the test case)
        }
        
        guard let casted = unwrappedValue as? Type else {
            fatalError("MockExporter: Could not cast value \(String(describing: unwrappedValue)) to type \(Type.self) for '\(parameter.description)'")
        }
        
        return casted
    }
}
#endif
