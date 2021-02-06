//
//  Handler+Never.swift
//  
//
//  Created by Paul Schmiedmayer on 1/11/21.
//

import NIO


extension Never: Encodable {
    /// Default implementation which will simply crash
    public func encode(to encoder: Encoder) throws {
        fatalError("The '\(Self.self)' type cannot be encoded")
    }
}

extension Never: ResponseTransformable {
    /// Default implementation which will simply crash
    public func transformToResponse(on eventLoop: EventLoop) -> EventLoopFuture<Response<Never>> {
        fatalError("The '\(Self.self)' type cannot be passed as a `ResponseTransformable`")
    }
}

extension Handler where Response == Never {
    /// Default implementation which will simply crash
    public func handle() -> Self.Response {
        fatalError("'\(Self.self).\(#function)' is not implemented because 'Self.Response' is set to '\(Self.Response.self)'")
    }
}

extension _EmptyComponentCustomNeverImpl: ResponseTransformable {
    /// Default implementation which will simply crash
    public func transformToResponse(on eventLoop: EventLoop) -> EventLoopFuture<Response<Never>> {
        fatalError("The '\(Self.self)' type cannot be passed as a `ResponseTransformable`")
    }
}

extension Handler where Response == _EmptyComponentCustomNeverImpl {
    /// Default implementation which will simply crash
    public func handle() -> Self.Response {
        fatalError("'\(Self.self).\(#function)' is not implemented because 'Self.Response' is set to '\(Self.Response.self)'")
    }
}
