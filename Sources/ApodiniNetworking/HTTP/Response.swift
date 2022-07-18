//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import NIO
import NIOHTTP1
import NIOWebSocket
import WebSocketKit
import Foundation
import Apodini
import ApodiniAuthorization


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
    /// Whether the request handler should ignore the value in the `version` property, and instead use the request's version.
    /// This option should be avoided if possible, and it really just here to accommodate very specific edge cases in which a response
    /// is created in a context where the matching HTTP request is not available, and we want to defer the selection of the HTTP version
    /// to the HTTPServer's request handler. In that case, you can pass any value to the initializer's version parameter, and then later,
    /// by setting this property to `true`, tell the server to ignore that value, and instead use the HTTP version found in the request object.
    /// - Note: This option will only affect the HTTP version the HTTP server writes into a response.
    ///         It has no effect in other situations, such as manually invoking handlers as part of the test suite.
    public var httpServerShouldIgnoreHTTPVersionAndInsteadMatchRequest = false // swiftlint:disable:this identifier_name
    
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
    
    /// Sets the `Content-Length` header to match the number of readable bytes currently in the response's body.
    public func setContentLengthForCurrentBody() {
        headers[.contentLength] = bodyStorage.readableBytes
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
                        // NOTE: this could potentially leak internal error messages
                        bodyStorage: .buffer(initialValue: "\(error)")
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

extension ApodiniError: HTTPResponseConvertible {
    private func extractHTTPResponseStatus() -> HTTPResponseStatus {
        // First try to extract a specific status code from the options
        if let status = self.option(for: .httpResponseStatus) {
            return status
        }
        
        // Then we see whether there's a ``AuthorizationErrorReason`` present
        if let reason = self.option(for: .authorizationErrorReason) {
            switch reason {
            case .authenticationRequired,
                    .invalidAuthenticationRequest,
                    .failedAuthentication,
                    .custom:
                return .unauthorized
            case .failedAuthorization:
                return .forbidden
            }
        }
        
        return HTTPResponseStatus(self.option(for: .errorType))
    }
    
    public func makeHTTPResponse(for request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        request.eventLoop.makeSucceededFuture(HTTPResponse(
            version: request.version,
            status: self.extractHTTPResponseStatus(),
            headers: HTTPHeaders {
                $0[.contentType] = .text
            },
            // the error's description is only included in DEBUG mode
            bodyStorage: .buffer(initialValue: self.message()))
        )
    }
}

public extension HTTPResponseStatus {
    init(_ apodiniErrorType: ErrorType) {
        switch apodiniErrorType {
        case .badInput:
            self = .badRequest
        case .notFound:
            self = .notFound
        case .unauthenticated:
            // This is correct, see https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/401
            self = .unauthorized
        case .forbidden:
            self = .forbidden
        case .serverError:
            self = .internalServerError
        case .notAvailable:
            self = .serviceUnavailable
        case .other:
            self = .internalServerError
        }
    }
}
