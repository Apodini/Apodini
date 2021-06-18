//
//  Status.swift
//  
//
//  Created by Paul Schmiedmayer on 2/3/21.
//

import NIO


/// An `Status` expresses additional information that can be passed to a `Response`
public enum Status: ResponseTransformable {
    /// The request was handled and the response contains the expected content
    case ok
    /// The request was handled and a new resource has been created
    case created
    /// The request was handled and the response does not contain any content
    case noContent
    /// The request was handled and the client should be redirected to another URL
    case redirect
    
    public func transformToResponse(on eventLoop: EventLoop) -> EventLoopFuture<Response<Empty>> {
        eventLoop.makeSucceededFuture(Response.final(self))
    }
}
