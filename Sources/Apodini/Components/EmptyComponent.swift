//
//  EmptyComponent.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import Vapor



// MARK: EndpointNode


extension Never: ResponseEncodable {
    /// Encodes an instance of `Self` to a `HTTPResponse
    ///
    /// `Never` must never be encoded!
    public func encodeResponse(for request: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        fatalError("Never should never be encoded")
    }
}


extension Never: EndpointNode {
    public typealias Response = Never
    
    public func handle() -> Never {
        fatalError("Can't invoke endpoint with 'Never' response type")
    }
}


extension EndpointNode where Response == Never {
    public func handle() -> Never {
        fatalError("Can't invoke endpoint with 'Never' response type")
    }
}



// MARK: EndpointProvidingNode


extension Never: EndpointProvidingNode {
    public var content: Never {
        fatalError()
    }
}


extension EndpointProvidingNode where Content == Never {
    public var content: Never {
        fatalError()
    }
}
