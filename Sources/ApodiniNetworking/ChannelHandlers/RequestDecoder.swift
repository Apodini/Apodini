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


class HTTPServerRequestDecoder: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias InboundOut = HTTPRequest
    typealias OutboundOut = HTTPResponse // Only in case of errors
    
    enum InvalidRequestError: Swift.Error {
        case unsupportedChunkedTransferEncoding(HTTPRequest)
    }
    
    private enum State {
        case ready
        case awaitingBody(HTTPRequest)
        case awaitingEnd(HTTPRequest)
        case closed
    }
    
    private var state: State = .ready
    private let logger: Logger
    private let hostname: Hostname
    private let isTLSEnabled: Bool
    
    
    init(hostname: Hostname, isTLSEnabled: Bool) {
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
            } else if req.headers[.transferEncoding].contains(.chunked) {
                handleError(
                    context: context,
                    requestVersion: req.version,
                    errorMessage: "'Transfer-Encoding: chunked' not supported. Use HTTP/2 instead."
                )
            } else {
                // Either there is no Content-Length header, or it has a size that doesn't match the body we were sent
                logger.error("Potentially unhandled incoming HTTP request")
                handleError(context: context, requestVersion: req.version, errorMessage: nil)
            }
        case let (.awaitingBody(req), .end(endHeaders: _)):
            context.fireChannelRead(wrapInboundOut(req))
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
