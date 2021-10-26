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


class HTTPServerRequestHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTPRequest
    typealias OutboundOut = HTTPResponse
    
    private let responder: HTTPResponder // TODO does this introduce a retain cycle?? (we're passing the server here, which holds a reference to the channel, to the pipeline of which this handler is added!!!!
    private var isCurrentlyWaitingOnSomeStream = false
    
    init(responder: HTTPResponder) {
        self.responder = responder
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let request = unwrapInboundIn(data)
        responder
            .respond(to: request)
            .makeHTTPResponse(for: request)
            .hop(to: context.eventLoop)
            .whenComplete { (result: Result<HTTPResponse, Error>) in
                switch result {
                case .failure(let error):
                    // NOTE: if we get an error here, that error is _NOT_ coming from the route's handler (since these error already got mapped into .internalServerError http responses previously in the chain...)
                    fatalError("Unexpectedly got a failed future: \(error)")
                case .success(let httpResponse):
                    if httpResponse.httpServerShouldIgnoreHTTPVersionAndInsteadMatchRequest {
                        httpResponse.version = request.version
                    }
                    switch httpResponse.bodyStorage {
                    case .buffer:
                        self.handleResponse(httpResponse, context: context)
                    case .stream(let stream):
                        stream.setObserver { [unowned httpResponse] _, _ in
                            context.eventLoop.execute { [unowned httpResponse] in
                                self.handleResponse(httpResponse, context: context)
                            }
                        }
                        self.handleResponse(httpResponse, context: context)
                    }
                }
            }
    }
    
    
    private func handleResponse(_ response: HTTPResponse, context: ChannelHandlerContext) {
        response.headers.setUnlessPresent(name: .date, value: Date())
        // Note might want to use this as an opportunity to log errors/warning if responses are lacking certain headers, to give clients the ability fo address this.
        context.write(self.wrapOutboundOut(response)).whenComplete { result in
            switch result {
            case .success:
                let keepAlive = false // If this is true, the channel will always be kept open. otherwise, it might be if it's a stream
                switch response.bodyStorage {
                case .buffer:
                    if !keepAlive {
                        context.close(mode: .output, promise: nil)
                    }
                case .stream(let stream):
                    if !keepAlive && stream.isClosed {
                        context.close(mode: .output, promise: nil)
                    }
                }
            case .failure(let error):
                self.errorCaught(context: context, error: error)
            }
        }
    }
}
