//
//  Action.swift
//
//
//  Created by Paul Schmiedmayer on 1/4/21.
//

import NIO


/// Used to return from the `handle` method
/// by `Components` that expose client-side streaming endpoints.
public enum Action<Element: Encodable> {
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
    /// No specific action was defined by the `Handler` or `EncodableResponseTransformer`.
    /// The eventual action will be decided by Apodini
    case automatic(_ element: Element)
    /// Closes the connection, without  sending a response.
    case end
}


extension Action {
    /// Maps an `Element` to an `Action` to an other `Element`
    /// - Parameter transform: The closure to transform the `Element`
    /// - Returns: The transformed `Action`
    public func map<T: Encodable>(_ transform: (Element) -> (T)) -> Action<T> {
        switch self {
        case .nothing:
            return .nothing
        case let .send(element):
            return .send(transform(element))
        case let .final(element):
            return .final(transform(element))
        case let .automatic(element):
            return .automatic(transform(element))
        case .end:
            return .end
        }
    }
}


extension Action {
    var typeErasured: Action<AnyEncodable> {
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
        case let .automatic(element):
            guard let anyEncodableElement = element as? AnyEncodable else {
                return .automatic(AnyEncodable(element))
            }
            return .automatic(anyEncodableElement)
        case .end:
            return .end
        }
    }
    
    var element: Element? {
        switch self {
        case .nothing, .end:
            return nil
        case let .send(element), let .final(element), let .automatic(element):
            return element
        }
    }
    
    func transform(using responseTransformer: AnyResponseTransformer, on eventLoop: EventLoop) -> EventLoopFuture<Action<AnyEncodable>> {
        responseTransformer.transform(response: self.typeErasured, on: eventLoop)
    }
}


extension Action where Element == AnyEncodable {
    func typed<T: Encodable>(_ type: T.Type = T.self) -> Action<T>? {
        switch self {
        case .nothing:
            return .nothing
        case let .send(element):
            return element.typed(T.self).map {
                .send($0)
            }
        case let .final(element):
            return element.typed(T.self).map {
                .final($0)
            }
        case let .automatic(element):
            return element.typed(T.self).map {
                .automatic($0)
            }
        case .end:
            return .end
        }
    }
}


// MARK: Action: Response
extension Action: Response {
    public typealias ResponseContent = Element
    
    public func action(on eventLoop: EventLoop) -> EventLoopFuture<Action<Element>> {
        eventLoop.makeSucceededFuture(self)
    }
}
