//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import NIO
import NIOHTTP1
import struct Apodini.Hostname
import Logging
import ApodiniNetworkingHTTPSupport


class HTTPServerRequestDecoder: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias InboundOut = HTTPRequest
    typealias OutboundOut = HTTPResponse // Only in case of errors
    
    enum InvalidRequestError: Swift.Error {
        case unsupportedChunkedTransferEncoding(HTTPRequest)
    }
    
    private enum State {
        /// The channel handler is ready to handle a new request.
        case ready
        /// The channel handler has received a HEADER frame, and is currently waiting for the request's body
        case awaitingBody(HTTPRequest)
        /// The channel handler is collecting the contents of a non-streaming request body.
        /// This is the case if the request's expected communication pattern is non-streaming and the specified `Content-Length` is larger than the so-far received data.
        case collectingNonStreamBody(HTTPRequest, expectedContentLength: Int)
        /// The channel handler is reading the contents of a streaming request,
        case readingBodyStream(HTTPRequest)
        /// The channel handler has finished reading the request body, and is now waiting for the request's end.
        case awaitingEnd(HTTPRequest)
        /// The channel handler has encountered an error, and is now closed.
        case closed
    }
    
    private var state: State = .ready
    private let logger: Logger
    private let responder: HTTPResponder
    private let hostname: Hostname
    private let isTLSEnabled: Bool
    
    
    init(responder: HTTPResponder, hostname: Hostname, isTLSEnabled: Bool) {
        self.responder = responder
        self.hostname = hostname
        self.isTLSEnabled = isTLSEnabled
        logger = Logger(label: "\(Self.self)")
    }
    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) { // swiftlint:disable:this cyclomatic_complexity
        let request = unwrapInboundIn(data)
        switch (state, request) {
        case (.ready, .head(let reqHead)):
            guard let url = URI(string: "\(hostname.uriPrefix(isTLSEnabled: isTLSEnabled))\(reqHead.uri)") else {
                logger.error("received invalid url: '\(reqHead.uri)' (full req head: \(reqHead)")
                handleError(context: context, requestVersion: reqHead.version, errorMessage: "Unable to process URL")
                return
            }
            let request = HTTPRequest(
                remoteAddress: context.channel.remoteAddress,
                version: reqHead.version,
                method: reqHead.method,
                url: url,
                headers: reqHead.headers,
                bodyStorage: .buffer(),
                eventLoop: context.eventLoop
            )
            state = .awaitingBody(request)
        
        case (.ready, .body):
            logger.error("Invalid state: received unexpected body (was waiting for head)")
        
        case (.ready, .end):
            logger.error("Invalid state: received unexpected end (was waiting for head)")
        
        case (.awaitingBody(let req), .head):
            handleError(
                context: context,
                requestVersion: req.version,
                errorMessage: "Received unexpected head when waiting for body"
            )
        
        case let (.awaitingBody(req), .body(bodyBuffer)):
            if req.headers[.contentLength] == bodyBuffer.readableBytes {
                req.bodyStorage = .buffer(bodyBuffer)
                state = .awaitingEnd(req)
            } else if req.headers[.transferEncoding].contains(.chunked) && req.version != .http2 {
                handleError(
                    context: context,
                    requestVersion: req.version,
                    errorMessage: "'Transfer-Encoding: chunked' not supported. Use HTTP/2 instead."
                )
            } else if let contentLength = req.headers[.contentLength], contentLength > bodyBuffer.readableBytes {
                req.bodyStorage = .buffer(bodyBuffer)
                state = .collectingNonStreamBody(req, expectedContentLength: contentLength)
            } else if let expectedCommPattern = responder.expectedCommunicationPattern(for: req), expectedCommPattern.isStream {
                req.bodyStorage = .stream()
                state = .readingBodyStream(req)
                context.fireChannelRead(wrapInboundOut(req))
                req.bodyStorage.stream!.write(bodyBuffer)
            } else {
                // Either there is no Content-Length header, or it has a size that doesn't match the body we were sent
                logger.error("Potentially unhandled incoming HTTP request")
                logger.error("headers: \(req.headers)")
                logger.error("reqBody: \(bodyBuffer)")
                handleError(context: context, requestVersion: req.version, errorMessage: nil)
            }
        
        case let (.awaitingBody(req), .end(endHeaders: _)):
            context.fireChannelRead(wrapInboundOut(req))
            state = .ready
        
        case let (.collectingNonStreamBody(req, _), .head):
            handleError(
                context: context,
                requestVersion: req.version,
                errorMessage: "Received unexpected head while collecting body"
            )
        
        case let (.collectingNonStreamBody(req, expectedContentLength), .body(bodyBuffer)):
            req.bodyStorage.write(bodyBuffer)
            switch req.bodyStorage.readableBytes.compareThreeWay(expectedContentLength) {
            case .orderedAscending:
                // There's still more data to come.
                break
            case .orderedDescending:
                logger.error("Received more request body data than expected (Content-Length header: \(expectedContentLength), received: \(req.bodyStorage.readableBytes))")
                fallthrough
            case .orderedSame:
                state = .awaitingEnd(req)
            }
        
        case let (.collectingNonStreamBody(req, _), .end):
            handleError(
                context: context,
                requestVersion: req.version,
                errorMessage: "Received unexpected end while collecting body"
            )
        
        case let (.readingBodyStream(req), .head):
            handleError(
                context: context,
                requestVersion: req.version,
                errorMessage: "Received unexpected head while reading body stream"
            )
        
        case let (.readingBodyStream(req), .body(bodyBuffer)):
            req.bodyStorage.stream!.write(bodyBuffer)
        
        case let (.readingBodyStream(req), .end):
            req.bodyStorage.stream!.close()
            state = .ready
        
        case (.awaitingEnd(let req), .head):
            handleError(
                context: context,
                requestVersion: req.version,
                errorMessage: "Received unexpected head when waiting for end"
            )
        
        case (.awaitingEnd(let req), .body):
            handleError(context: context, requestVersion: req.version, errorMessage: nil)
        
        case let (.awaitingEnd(req), .end(endHeaders: _)):
            context.fireChannelRead(wrapInboundOut(req))
            state = .ready
        
        case (.closed, .head):
            logger.error("Received unexpected head: already closing.")
        
        case (.closed, .body):
            logger.error("Received unexpected body: already closing.")
        
        case (.closed, .end):
            // this is fine
            break
        }
    }
    
    
    private func handleError(context: ChannelHandlerContext, requestVersion: HTTPVersion, errorMessage: String?) {
        let response = HTTPResponse(
            version: requestVersion,
            status: .internalServerError,
            headers: HTTPHeaders(),
            bodyStorage: .buffer(initialValue: "Internal Server Error")
        )
        if let errorMessage = errorMessage {
            response.bodyStorage.write(": \(errorMessage)")
        }
        self.state = .closed
        _ = context.writeAndFlush(wrapOutboundOut(response))
            .flatMap { context.close(mode: .all) }
    }
}
