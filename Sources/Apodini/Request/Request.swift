//
//  Request.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO

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
    
    func enterRequestContext<E, T>(with element: E, executing method: (E) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
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
                    return context.eventLoop.makeFailedFuture(error)
                }
            }
        }
        
        return method(element)
    }
}
