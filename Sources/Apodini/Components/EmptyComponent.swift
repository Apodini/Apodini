//
//  EmptyComponent.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO


extension Never: Component {
    public var content: Never {
        fatalError("Never Type has no body")
    }
    
    
    public func handle(_ request: Request) -> EventLoopFuture<Never> {
        request.eventLoop.makeFailedFuture(HTTPError.notImplemented)
    }
    
    public func visit<V>(_ visitor: inout V) where V: Visitor { }
}


extension Never: Codable {
    public init(from decoder: Decoder) throws {
        fatalError("Never should never be decoded")
    }
    
    public func encode(to encoder: Encoder) throws {
        fatalError("Never should never be encoded")
    }
}


extension Component where Content == Never {
    public var content: Never {
        fatalError("\(type(of: self)) has no body")
    }
}


extension Component where Response == Never {
    public func handle(_ request: Request) -> EventLoopFuture<Never> {
        request.eventLoop.makeFailedFuture(HTTPError.notImplemented)
    }
}


public struct EmptyComponent: Component {
    public init() {}
    
    
    public func visit<V>(_ visitor: inout V) where V: Visitor { }
}
