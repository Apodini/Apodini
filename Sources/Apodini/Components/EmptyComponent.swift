//
//  EmptyComponent.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import Vapor


extension Never: Component {
    public typealias Content = Never
    public typealias Response = Never
    
    public var content: Self.Content {
        fatalError("Never Type has no body")
    }
    
    
    public func handle(_ request: Vapor.Request) -> EventLoopFuture<Self.Response> {
        fatalError("Never should never be handled")
    }
    
    public func visit<V>(_ visitor: inout V) where V: Visitor { }
}


extension Never: ResponseEncodable {
    public func encodeResponse(for request: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        fatalError("Never should never be encoded")
    }
}


extension Component where Self.Content == Never {
    public var content: Self.Content {
        fatalError("\(type(of: self)) has no body")
    }
}


extension Component where Self.Response == Never {
    public func handle(_ request: Vapor.Request) -> EventLoopFuture<Self.Response> {
        fatalError("Never should never be handled")
    }
}


public struct EmptyComponent: Component {
    public init() {}
    
    
    public func visit<V>(_ visitor: inout V) where V: Visitor { }
}
