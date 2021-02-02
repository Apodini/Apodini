//
//  Response.swift
//
//
//  Created by Paul Schmiedmayer on 1/4/21.
//

import NIO


/// Used to return from the `handle` method by `Handler`s
public enum Response<Element: Encodable>: ResponseTransformable {
    /// Indicates that the request was processed
    /// and **no** response should be sent to the client.
    case nothing
    /// Indicates that the given `Element` should be sent
    /// to the client, and more elements might follow.
    case send(_ element: Element)
    /// Indicates that the given `Element` should be sent
    /// as a final response to the client.
    /// Will be the last message on the stream sent by the server.
    case final(_ element: Element)
    /// Closes the connection, without  sending a response.
    case end
    
    
    public func transformToResponse(on eventLoop: EventLoop) -> EventLoopFuture<Response<Element>> {
        eventLoop.makeSucceededFuture(self)
    }
}


extension Response {
    /// Maps an `Element` to an `Response` to an other `Element`
    /// - Parameter transform: The closure to transform the `Element`
    /// - Returns: The transformed `Response`
    public func map<T: Encodable>(_ transform: (Element) -> (T)) -> Response<T> {
        switch self {
        case .nothing:
            return .nothing
        case let .send(element):
            return .send(transform(element))
        case let .final(element):
            return .final(transform(element))
        case .end:
            return .end
        }
    }
}


extension Response {
    var typeErasured: Response<AnyEncodable> {
        switch self {
        case .nothing:
            return .nothing
        case let .send(element):
            guard let anyEncodableElement = element as? AnyEncodable else {
                return .send(AnyEncodable(element))
            }
            return .send(anyEncodableElement)
        case let .final(element):
            guard let anyEncodableElement = element as? AnyEncodable else {
                return .final(AnyEncodable(element))
            }
            return .final(anyEncodableElement)
        case .end:
            return .end
        }
    }
    
    var element: Element? {
        switch self {
        case .nothing, .end:
            return nil
        case let .send(element), let .final(element):
            return element
        }
    }
}


extension Response where Element == AnyEncodable {
    func typed<T: Encodable>(_ type: T.Type = T.self) -> Response<T>? {
        switch self {
        case .nothing:
            return .nothing
        case let .send(element):
            return element.typed(type).map {
                .send($0)
            }
        case let .final(element):
            return element.typed(type).map {
                .final($0)
            }
        case .end:
            return .end
        }
    }
}

extension Response where Element == EnrichedContent {
    func typed<T: Encodable>(_ type: T.Type = T.self) -> Response<T>? {
        switch self {
        case .nothing:
            return .nothing
        case let .send(element):
            return element.typed(type).map {
                .send($0)
            }
        case let .final(element):
            return element.typed(type).map {
                .final($0)
            }
        case .end:
            return .end
        }
    }
}
