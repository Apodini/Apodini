//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import NIO
import NIOHTTP1


/// An `Status` expresses additional information that can be passed to a `Response`
public enum Status: ResponseTransformable, Equatable {
    /// The request was handled and the response contains the expected content
    case ok
    /// The request was handled and a new resource has been created
    case created
    /// The request was handled and the response does not contain any content
    case noContent
    
    /// The request was handled and the client should be redirected to another URL
    case redirect
    /// The request was handled and the response has not been changed versus the client's cache.
    case notModified
    
    /// The request was not handled as the request was malformed.
    case badRequest
    /// The request was not handled as the resource could not be found
    case notFound
    
    public func transformToResponse(on eventLoop: EventLoop) -> EventLoopFuture<Response<Empty>> {
        eventLoop.makeSucceededFuture(Response.final(self))
    }
}
