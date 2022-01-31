//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import NIO
import ApodiniUtils


public struct Response<Content: Encodable>: ResponseTransformable {
    public static var nothing: Response<Content> {
        Response<Content>(information: InformationSet(), connectionEffect: .open)
    }
    
    public static var end: Response<Content> {
        Response<Content>(information: InformationSet(), connectionEffect: .close)
    }

    public static func end(status: Status? = nil, information: [AnyInformation] = []) -> Response<Content> {
        Response<Content>(status: status, information: information, connectionEffect: .close)
    }

    public static func end(status: Status? = nil, information: AnyInformation...) -> Response<Content> {
        Response<Content>(status: status, information: information, connectionEffect: .close)
    }


    public static func send(_ content: Content, status: Status? = nil, information: [AnyInformation] = []) -> Response<Content> {
        // nil must not be passable by the user as a value
        Response<Content>(status: status, content: content, information: information, connectionEffect: .open)
    }

    public static func send(_ content: Content, status: Status? = nil, information: AnyInformation...) -> Response<Content> {
        // nil must not be passable by the user as a value
        Response<Content>(status: status, content: content, information: information, connectionEffect: .open)
    }


    public static func send(_ status: Status? = nil, information: [AnyInformation] = []) -> Response<Content> {
        Response<Content>(status: status, information: information, connectionEffect: .open)
    }

    public static func send(_ status: Status? = nil, information: AnyInformation...) -> Response<Content> {
        Response<Content>(status: status, information: information, connectionEffect: .open)
    }


    public static func final(_ content: Content, status: Status? = nil, information: [AnyInformation] = []) -> Response<Content> {
        // nil must not be passable by the user as a value
        Response<Content>(status: status, content: content, information: information, connectionEffect: .close)
    }

    public static func final(_ content: Content, status: Status? = nil, information: AnyInformation...) -> Response<Content> {
        // nil must not be passable by the user as a value
        Response<Content>(status: status, content: content, information: information, connectionEffect: .close)
    }

    
    public static func final(_ status: Status? = nil, information: [AnyInformation] = []) -> Response<Content> {
        Response<Content>(status: status, information: information, connectionEffect: .close)
    }

    public static func final(_ status: Status? = nil, information: AnyInformation...) -> Response<Content> {
        Response<Content>(status: status, information: information, connectionEffect: .close)
    }

    
    public let status: Status?
    public let content: Content?
    public var information: InformationSet
    public let connectionEffect: ConnectionEffect

    private init(status: Status? = nil, content: Content? = nil, information: [AnyInformation] = [], connectionEffect: ConnectionEffect) {
        self.init(status: status, content: content, information: InformationSet(information), connectionEffect: connectionEffect)
    }

    private init(status: Status? = nil, content: Content? = nil, information: InformationSet = [], connectionEffect: ConnectionEffect) {
        self.status = status
        self.content = content
        self.information = information
        self.connectionEffect = connectionEffect
    }
    
    
    public func transformToResponse(on eventLoop: EventLoop) -> EventLoopFuture<Response<Content>> {
        eventLoop.makeSucceededFuture(self)
    }
    
    public var isNothing: Bool {
        status == nil && content == nil && information.isEmpty && connectionEffect == .open
    }
}


extension Response {
    /// Maps an `Self.Content` to an `Response` with an other `Self.Content`
    /// - Parameter transform: The closure to transform the `Self.Content`
    /// - Returns: The transformed `Response`
    public func map<T: Encodable>(_ transform: (Self.Content) throws -> (T)) rethrows -> Response<T> {
        Response<T>(status: status, content: try content.map(transform), information: information, connectionEffect: connectionEffect)
    }
}


extension Response {
    /// Provides a type-erased version of the ``Response`` by wrapping the ``content`` into an `AnyEncodable`.
    public var typeErased: Response<AnyEncodable> {
        map { content in
            guard let anyEncodable = content as? AnyEncodable else {
                return AnyEncodable(content)
            }
            return anyEncodable
        }
    }
}


extension Response {
    func typed<T: Encodable>(_ type: T.Type = T.self) -> Response<T>? {
        if let anyEncodable = content as? AnyEncodable, let typedContent = anyEncodable.typed(type) {
            return Response<T>(status: status, content: typedContent, information: information, connectionEffect: connectionEffect)
        } else if let content = content {
            if let typedContent = content as? T {
                return Response<T>(status: status, content: typedContent, information: information, connectionEffect: connectionEffect)
            } else {
                return nil
            }
        } else {
            return Response<T>(status: status, content: nil, information: information, connectionEffect: connectionEffect)
        }
    }
}
