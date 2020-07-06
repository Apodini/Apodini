//
//  Request.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import Vapor


protocol RequestInjectable {
    func inject(using request: Request) throws
    func disconnect()
}


public struct Request {
    public let httpType: HTTPType
    public let headers: [String: String]
    public let body: ByteBuffer
    public let context: Context
    
    
    public var eventLoop: EventLoop {
        context.eventLoop
    }
    
    
    init(httpType: HTTPType = .get,
         headers: [String: String] = [:],
         body: ByteBuffer = ByteBuffer(),
         context: Context) {
        self.httpType = httpType
        self.headers = headers
        self.body = body
        self.context = context
    }
    
    func enterRequestContext<E, R>(with element: E, executing method: (E) -> R) -> R {
        let viewMirror = Mirror(reflecting: element)
        
        defer {
            for child in viewMirror.children {
                if let anyCurrentDatabase = child.value as? RequestInjectable {
                    anyCurrentDatabase.disconnect()
                }
            }
        }
        
        // Inject all properties that can be injected using RequestInjectable
        for child in viewMirror.children {
            if let anyCurrentDatabase = child.value as? RequestInjectable {
                do {
                    try anyCurrentDatabase.inject(using: self)
                } catch {
                    fatalError("Could not inject a value into a \(child.label ?? "UNKNOWN") property wrapper.")
                }
            }
        }
        
        return method(element)
    }
}
