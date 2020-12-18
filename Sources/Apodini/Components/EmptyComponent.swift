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
    
    
    public func handle() -> Self.Response {
        fatalError("Never should never be handled")
    }
}


extension Never: ResponseEncodable {
    /// Encodes an instance of `Self` to a `HTTPResponse
    ///
    /// `Never` must never be encoded!
    public func encodeResponse(for request: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        fatalError("Never should never be encoded")
    }
}

extension Never: Encodable {
    public func encode(to encoder: Encoder) throws {
        fatalError("Never should never be encoded")
    }
}


extension Component where Self.Content == Never {
    /// This `Component` does not include any child `Component`s
    public var content: Never {
        fatalError("\(type(of: self)) has no body")
    }
}

extension Component where Self.Response == Never {
    /// This `Component` does not handle any network requests
    public func handle() -> Never {
        fatalError("Never should never be handled")
    }
}


public struct EmptyComponent: Component {
    public init() {}
}


extension EmptyComponent: Visitable {
    func visit(_ visitor: SyntaxTreeVisitor) {}
}
