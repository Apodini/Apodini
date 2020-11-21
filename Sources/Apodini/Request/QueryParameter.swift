//
//  QueryParameter.swift
//  
//
//  Created by Lorena Schlesinger on 21.11.20.
//

import Vapor
import Foundation


@propertyWrapper
public class QueryParameter<Element: Decodable>: RequestInjectable {
    private var element: Element?
    private(set) var key: String
    
    public var wrappedValue: Element {
        guard let element = element else {
            fatalError("You can only access the query parameter while you handle a request.")
        }
        return element
    }
    
    public init(key: String) {
        self.key = key
    }
    
    func inject(using request: Vapor.Request) throws {
        element = try request.query.get(at: key)
    }
    
    func disconnect() {
        self.element = nil
    }
}
