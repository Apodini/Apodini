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
    
    
    func inject(using request: Request) throws {
        guard let byteBuffer = request.body.data, let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) else {
            throw HTTPError.internalServerError(reason: "Could not read the HTTP request's body")
        }
        
        element = try JSONDecoder().decode(Element.self, from: data)
    }
    
    func disconnect() {
        self.element = nil
    }
}
