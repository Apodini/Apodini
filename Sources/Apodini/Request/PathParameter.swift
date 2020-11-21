//
//  PathParameter.swift
//  
//
//  Created by Lorena Schlesinger on 21.11.20.
//

import Foundation
import Vapor

@propertyWrapper
public class PathParameter<Element: LosslessStringConvertible>: RequestInjectable {
    private var element: Element?
    private(set) var key: String
    
    public var wrappedValue: Element {
        guard let element = element else {
            fatalError("You can only access the path parameter while you handle a request.")
        }
        return element
    }
    
    public init(key: String) {
        self.key = key
    }
    
    func inject(using request: Vapor.Request) throws {
        element = request.parameters.get(key)
    }
    
    func disconnect() {
        self.element = nil
    }
}
