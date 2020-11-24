//
//  Body.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor
import Foundation


@propertyWrapper
public class Parameter<Element: Codable> {
    public enum ParameterType {
        case automatic
        case content
        case lightweight
        case path
    }
    
    struct PathParameterID<Element> {
        let id: UUID
    }
    
    private var element: Element?
    private var name: String?
    private var parameterType: ParameterType = .automatic
    private var id: UUID = UUID()
    
    
    public var wrappedValue: Element {
        guard let element = element else {
            fatalError("You can only access the body while you handle a request")
        }
        
        return element
    }
    
    public var projectedValue: Parameter {
        guard parameterType == .path || parameterType == .automatic else {
            preconditionFailure("Only `.path` or `.automatic` parameters are allowed to be passed to a `Component`.")
        }
        
        return Parameter(name: self.name, parameterType: .path, id: self.id)
    }
    
    public init(_ parameterType: ParameterType = .automatic) {
        self.parameterType = parameterType
    }
    
    public init(_ name: String, _ parameterType: ParameterType = .automatic) {
        self.name = name
        self.parameterType = parameterType
    }
    
    private init(_ pathParameterID: PathParameterID<Element>) {
        self.parameterType = .path
        self.id = pathParameterID.id
    }
    
    private init(name: String?, parameterType: ParameterType, id: UUID) {
        self.name = name
        self.parameterType = parameterType
        self.id = id
    }
}

extension Parameter: RequestInjectable {
    func inject(using request: Vapor.Request, with decoder: SemanticModelBuilder?) throws {
        if let decoder = decoder {
            element = try decoder.decode(Element.self, from: request)
        }
    }
    
    func disconnect() {
        self.element = nil
    }
}
