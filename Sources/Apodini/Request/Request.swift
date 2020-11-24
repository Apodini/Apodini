//
//  Request.swift
//  
//
//  Created by Paul Schmiedmayer on 7/12/20.
//

import Vapor


@propertyWrapper
public struct Request: RequestInjectable {
    internal var request: Vapor.Request? = nil
    
    
    public var wrappedValue: Vapor.Request {
        guard let request = request else {
            fatalError("You can only access the request while you handle a request")
        }
        
        return request
    }
    
    
    public init() { }
    
    
    mutating func inject(using request: Vapor.Request, with decoder: SemanticModelBuilder? = nil) throws {
        self.request = request
    }
}
