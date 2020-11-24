//
//  Body.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIOFoundationCompat
import Vapor
import Foundation


@propertyWrapper
public class Body<Element: Codable>: RequestInjectable {
    private var element: Element?
    
    
    public var wrappedValue: Element {
        guard let element = element else {
            fatalError("You can only access the body while you handle a request")
        }
        
        return element
    }
    
    
    public init() { }
    
    
    func inject(using request: Vapor.Request, with decoder: SemanticModelBuilder?) throws {
        if let decoder = decoder {
            element = try decoder.decode(Element.self, from: request)
        }
    }
    
    func disconnect() {
        self.element = nil
    }
}
