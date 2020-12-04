//
//  Request.swift
//  
//
//  Created by Paul Schmiedmayer on 7/12/20.
//

import Vapor


@propertyWrapper
// swiftlint:disable:next type_name
struct _Request: RequestInjectable {
    private var request: Vapor.Request?
    
    
    var wrappedValue: Vapor.Request {
        guard let request = request else {
            fatalError("You can only access the request while you handle a request")
        }
        
        return request
    }
    
    
    init() { }
    
    
    mutating func inject(using request: Vapor.Request, with decoder: SemanticModelBuilder? = nil) throws {
        self.request = request
    }
}
