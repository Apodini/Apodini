import NIO
import NIOHTTP1
import NIOWebSocket
import WebSocketKit
import Foundation


/// A HTTP response, i.e. a response to a `HTTPRequest`
public class HTTPResponse {
    /// This response's HTTP version
    public var version: HTTPVersion
    /// The HTTP status code to be sent alongside this response
    public var status: HTTPResponseStatus
    /// The HTTP headers to be sent alongside this response
    public var headers: HTTPHeaders
    /// This response's body. This can be either a buffer-, or a stream-based body, see the `BodyStorage` type for more info.
    public var bodyStorage: BodyStorage
    
    /// Creates a new `HTTPResponse` from the specified values.
    /// - Note: Most of these intentionally do not have default values, this is to ensure that a caller doesn't accidentally construct incorrect responses, e.g. containing an incorrect HTTP version.
    public init(
        version: HTTPVersion,
        status: HTTPResponseStatus,
        headers: HTTPHeaders,
        bodyStorage: BodyStorage = .buffer()
    ) {
        self.version = version
        self.status = status
        self.headers = headers
        self.bodyStorage = bodyStorage
    }
}


/// A HTTP response that performs a protocol upgrade
internal class HTTPUpgradingResponse: HTTPResponse {
    enum Upgrade {
        case webSocket(
            maxFrameSize: Int,
            shouldUpgrade: () -> EventLoopFuture<HTTPHeaders?>,
            onUpgrade: (WebSocket) -> Void
        )
    }
    
    var upgrade: Upgrade
    
    init(version: HTTPVersion, status: HTTPResponseStatus, headers: HTTPHeaders, bodyStorage: BodyStorage = .buffer(), upgrade: Upgrade) {
        self.upgrade = upgrade
        super.init(version: version, status: status, headers: headers, bodyStorage: bodyStorage)
    }
}


extension HTTPRequest {
    /// Creates, in response to this request, a HTTP upgrade response for switching the protocol from HTTP to WebSocket.
    public func makeWebSocketUpgradeResponse(
        maxFrameSize: Int = 1 << 14,
        shouldUpgrade: @escaping (HTTPRequest) -> EventLoopFuture<HTTPHeaders?> = { $0.eventLoop.makeSucceededFuture([:]) },
        onUpgrade: @escaping (HTTPRequest, WebSocket) -> Void
    ) -> HTTPResponse {
        HTTPUpgradingResponse(
            version: self.version,
            status: .switchingProtocols,
            headers: [:],
            bodyStorage: .buffer(),
            upgrade: .webSocket(
                maxFrameSize: maxFrameSize,
                shouldUpgrade: { shouldUpgrade(self) },
                onUpgrade: { onUpgrade(self, $0) }
            )
        )
    }
}


/// A type which can be turned into an `EventLoopFuture<HTTPResponse>`
public protocol HTTPResponseConvertible {
    /// Create an `EventLoopFuture<HTTPResponse>` in response to the `HTTPRequest`.
    /// - Note: You can use this function to implement custom error handling for your types. If you return a failed EventLoopFuture,
    ///         ApodiniNetworking will convert that into an error HTTP response for you.
    ///         You also can implement this "failed future -> error response" conversion manually, by simply returning a succeeded EventLoopFuture
    ///         where the contained value is your custom error `HTTPResponse` object.
    func makeHTTPResponse(for request: HTTPRequest) -> EventLoopFuture<HTTPResponse>
}


extension HTTPResponse: HTTPResponseConvertible {
    public func makeHTTPResponse(for request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        request.eventLoop.makeSucceededFuture(self)
    }
}


extension EventLoopFuture: HTTPResponseConvertible where Value: HTTPResponseConvertible {
    public func makeHTTPResponse(for request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        self.flatMapAlways { (result: Result<Value, Error>) -> EventLoopFuture<HTTPResponse> in
            switch result {
            case .success(let value):
                return value.makeHTTPResponse(for: request)
            case .failure(let error):
                if let error = error as? HTTPResponseConvertible {
                    return error.makeHTTPResponse(for: request)
                } else {
                    return request.eventLoop.makeSucceededFuture(HTTPResponse(
                        version: request.version,
                        status: .internalServerError,
                        headers: HTTPHeaders {
                            $0[.contentType] = .text
                        },
                        bodyStorage: .buffer(initialValue: "\(error)") // TODO this risks leaking internal error info!!! Are we fine w/ that?
                    ))
                }
            }
        }
    }
}


extension String: HTTPResponseConvertible {
    public func makeHTTPResponse(for request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        request.eventLoop.makeSucceededFuture(HTTPResponse(
            version: request.version,
            status: .ok,
            headers: HTTPHeaders {
                $0[.contentType] = .text
            },
            bodyStorage: .buffer(initialValue: self)
        ))
    }
}


extension Data: HTTPResponseConvertible {
    public func makeHTTPResponse(for request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        request.eventLoop.makeSucceededFuture(HTTPResponse(
            version: request.version,
            status: .ok,
            headers: [:],
            bodyStorage: .buffer(initialValue: self)
        ))
    }
}


extension ByteBuffer: HTTPResponseConvertible {
    public func makeHTTPResponse(for request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        request.eventLoop.makeSucceededFuture(HTTPResponse(
            version: request.version,
            status: .ok,
            headers: [:],
            bodyStorage: .buffer(initialValue: self)
        ))
    }
}


/// An Error type which can be thrown in block-based `HTTPResponder`s that will be turned into HTTP error responses
public struct HTTPAbortError: Swift.Error, HTTPResponseConvertible {
    let status: HTTPResponseStatus
    let message: String?
    
    public init(status: HTTPResponseStatus, message: String? = nil) {
        self.status = status
        self.message = message
    }
    
    public func makeHTTPResponse(for request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        request.eventLoop.makeSucceededFuture(HTTPResponse(
            version: request.version,
            status: status,
            headers: [:],
            bodyStorage: .buffer(initialValue: message ?? "")
        ))
    }
}
