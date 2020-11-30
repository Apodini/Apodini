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
public struct Body<Element: Codable>: RequestInjectable {
    private var element: Element?
    
    
    public var wrappedValue: Element {
        guard let element = element else {
            fatalError("You can only access the body while you handle a request")
        }
        
        return element
    }
    
    
    public init() { }
    
    
    mutating func inject(using request: Vapor.Request, with decoder: RequestInjectableDecoder?) throws {
        if let decoder = decoder {
            element = try decoder.decode(Element.self, from: request)
        }
    }
}
