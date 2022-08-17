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
    
    private let responder: HTTPResponder
    private var channelClosed = false
    private var lastHTTPResponse: HTTPResponse?
    
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
                    self.lastHTTPResponse = httpResponse
                    if httpResponse.httpServerShouldIgnoreHTTPVersionAndInsteadMatchRequest {
                        httpResponse.version = request.version
                    }
                    switch httpResponse.bodyStorage {
                    case .buffer:
                        self.handleResponse(httpResponse, context: context)
                    case .stream(let stream):
                        stream.setObserver { [weak httpResponse] _, _ in
                            print("Stream observer called!")
                            context.eventLoop.execute { [weak httpResponse] in
                                print("EventLoop block in stream observer")
                                self.handleResponse(httpResponse, context: context)
                            }
                        }
                        self.handleResponse(httpResponse, context: context)
                    }
                }
            }
    }
    
    
    private func handleResponse(_ resp: HTTPResponse?, context: ChannelHandlerContext) {
        let response: HTTPResponse?
        if resp != nil {
            response = resp
        } else {
            response = lastHTTPResponse
        }
        guard let response = response else {
            return
        }
        
        response.headers.setUnlessPresent(name: .date, value: Date())
        if response.bodyStorage.isBuffer {
            response.headers.setUnlessPresent(name: .contentLength, value: response.bodyStorage.readableBytes)
        }
        response.headers.setUnlessPresent(name: .server, value: "ApodiniNetworking")
        // Note might want to use this as an opportunity to log errors/warning if responses are lacking certain headers, to give clients the ability to address this.
        print("SwiftNIO-writing \(response.bodyStorage.readableBytes) bytes")
        context.write(self.wrapOutboundOut(response)).whenComplete { result in
            print("Successfully sent \(response.bodyStorage.readableBytes) bytes")
            switch result {
            case .success:
                let keepAlive = false // If this is true, the channel will always be kept open. otherwise, it might be if it's a stream
                switch response.bodyStorage {
                case .buffer:
                    if !keepAlive {
                        self.channelClosed = true
                        context.close(promise: nil)
                    }
                case .stream(let stream):
                    if !keepAlive && stream.isClosed && stream.readableBytes == 0 {
                        print("Closing swift nio channel as Apodini stream is closed")
                        self.channelClosed = true
                        context.close(promise: nil)
                    }
                }
            case .failure(let error):
                self.errorCaught(context: context, error: error)
            }
        }
    }
}
