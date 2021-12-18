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


class HTTPServerRequestDecoder: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias InboundOut = HTTPRequest
    
    private enum State {
        case ready
        case awaitingBody(HTTPRequest)
        case awaitingEnd(HTTPRequest)
    }
    
    private var state: State = .ready
    private let hostname: Hostname
    private let isTLSEnabled: Bool
    
    
    init(hostname: Hostname, isTLSEnabled: Bool) {
        self.hostname = hostname
        self.isTLSEnabled = isTLSEnabled
    }
    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) { // swiftlint:disable:this cyclomatic_complexity
        let request = unwrapInboundIn(data)
        switch (state, request) {
        case (.ready, .head(let reqHead)):
            guard let url = URI(string: "\(hostname.uriPrefix(isTLSEnabled: isTLSEnabled))\(reqHead.uri)") else {
                fatalError("received invalid url: '\(reqHead.uri)'")
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
            fatalError("Invalid state: received unexpected body (was waiting for head)")
        case (.ready, .end):
            fatalError("Invalid state: received unexpected end (was waiting for head)")
        case (.awaitingBody, .head):
            fatalError("Invalid state: received unexpected head (was waiting for body)")
        case let (.awaitingBody(req), .body(bodyBuffer)):
            print("Awaiting Body. Received Body. Body: \(bodyBuffer)")
            if req.headers[.contentLength] == bodyBuffer.readableBytes {
                req.bodyStorage = .buffer(bodyBuffer)
                state = .awaitingEnd(req)
            } else {
                fatalError("Not yet implemented")
            }
        case let (.awaitingBody(req), .end(endHeaders)):
            context.fireChannelRead(wrapInboundOut(req))
            state = .ready
        case (.awaitingEnd, .head):
            fatalError("Invalid state: received unexpected head (was waiting for end)")
        case (.awaitingEnd, .body):
            fatalError("Invalid state: received unexpected body (was waiting for end)")
        case let (.awaitingEnd(req), .end(endHeaders)):
            print("Awaiting End. Got End.", req, endHeaders)
            context.fireChannelRead(wrapInboundOut(req))
            state = .ready
        }
    }
}
