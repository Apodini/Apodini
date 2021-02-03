//
//  Response.swift
//
//
//  Created by Paul Schmiedmayer on 1/4/21.
//

import NIO


public struct Empty: Encodable {
    fileprivate init() {}
}


public struct Response<Content: Encodable>: ResponseTransformable {
    public static var nothing: Response<Content> {
        Response<Content>(connectionEffect: .open)
    }
    
    public static var end: Response<Content> {
        Response<Content>(connectionEffect: .close)
    }
    
    
    public static func send(_ content: Self.Content, status: Status? = nil) -> Response<Self.Content> {
        Response<Self.Content>(status: status, content: content, connectionEffect: .open)
    }
    
    public static func send(_ status: Status? = nil) -> Response<Content> {
        Response<Content>(status: status, connectionEffect: .open)
    }
    
    public static func final(_ content: Self.Content, status: Status? = nil) -> Response<Self.Content> {
        Response<Self.Content>(status: status, content: content, connectionEffect: .close)
    }
    
    public static func final(_ status: Status? = nil) -> Response<Content> {
        Response<Content>(status: status, connectionEffect: .close)
    }
    
    
    let status: Status?
    let content: Self.Content?
    let connectionEffect: ConnectionEffect
    
    
    private init(status: Status? = nil, content: Self.Content? = nil, connectionEffect: ConnectionEffect) {
        self.status = status
        self.content = content
        self.connectionEffect = connectionEffect
    }
    
    
    public func transformToResponse(on eventLoop: EventLoop) -> EventLoopFuture<Response<Content>> {
        eventLoop.makeSucceededFuture(self)
    }
}


extension Response {
    /// Maps an `Self.Content` to an `Response` with an other `Self.Content`
    /// - Parameter transform: The closure to transform the `Self.Content`
    /// - Returns: The transformed `Response`
    public func map<T: Encodable>(_ transform: (Self.Content) -> (T)) -> Response<T> {
        Response<T>(status: status, content: content.map(transform), connectionEffect: connectionEffect)
    }
    
    /// Flat maps an `Self.Content` to an `Response` with an other `Self.Content`
    /// - Parameter transform: The closure to transform the `Self.Content`
    /// - Returns: The transformed `Response`
    public func flatMap<T: Encodable>(_ transform: (Self.Content) -> (T?)) -> Response<T>? {
        Response<T>(status: status, content: content.flatMap(transform), connectionEffect: connectionEffect)
    }
}


extension Response {
    var typeErasured: Response<AnyEncodable> {
        map { content in
            guard let anyEncodable = content as? AnyEncodable else {
                return AnyEncodable(content)
            }
            return anyEncodable
        }
    }
}


extension Response where Self.Content == AnyEncodable {
    func typed<T: Encodable>(_ type: T.Type = T.self) -> Response<T>? {
        flatMap { anyEncodable in
            anyEncodable.typed(type)
        }
    }
}

extension Response where Self.Content == EnrichedContent {
    func typed<T: Encodable>(_ type: T.Type = T.self) -> Response<T>? {
        flatMap { enrichedContent in
            enrichedContent.typed(type)
        }
    }
}
