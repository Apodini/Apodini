//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import NIO
import NIOHTTP2
import NIOHPACK
import Logging
import ProtobufferCoding
import ApodiniUtils


class GRPCMessageHandler: ChannelInboundHandler {
    typealias InboundIn = Input
    typealias OutboundOut = Output
    
    private static var requestIdCounter = Counter<UInt>()
    
    enum Input {
        case openStream(HPACKHeaders)
        case message(GRPCMessageIn)
        case closeStream
    }
    
    // NOT an RPC response message!!! this is the wrapper type encapsulating the different kinds of responses which can come out of the `GRPCMessageHandler`.
    enum Output {
        /// A call resulted in an error.
        /// - parameter connectionCtx: The GRPCStreamConnectionContext belonging to this connection.
        ///         Nil if the channel encounters an error before a connection context was created.
        case error(GRPCStatus, _ connectionCtx: GRPCStreamConnectionContextImpl?)
        
        /// A call resulted in a message
        case message(GRPCMessageOut, GRPCStreamConnectionContextImpl)
        case closeStream(trailers: HPACKHeaders)
    }
    
    private /*unowned?*/ let server: GRPCServer
    
    private var connectionCtx: GRPCStreamConnectionContextImpl?
    private let handleQueue = EventLoopFutureQueue()
    private var isConnectionClosed = false
    private var logger: Logger
    
    
    init(server: GRPCServer) {
        self.server = server
        self.logger = Logger(label: "[\(Self.self)]")
    }
    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) { // swiftlint:disable:this cyclomatic_complexity
        guard !isConnectionClosed else {
            fatalError("[\(Self.self)] received data on channel, even though the connection should already be closed")
        }
        switch unwrapInboundIn(data) {
        case .openStream(let headers):
            precondition(connectionCtx == nil, "Received .openStream even though we alrready have a connection up and running.")
            let splitPath = headers[.pathPseudoHeader]!.split(separator: "/")
            let (serviceName, methodName) = (String(splitPath[0]), String(splitPath[1]))
            guard let rpcHandler = server.makeStreamRPCHandler(toService: serviceName, method: methodName) else {
                // A nil return value indicates that the method does not exist.
                // gRPC says we have to handle this by responding w/ the corresponding status code
                print("Attempted to open channel to non-existing method '\(serviceName)/\(methodName)'")
                _ = self.handleQueue.submit(on: context.eventLoop) { () -> EventLoopFuture<Void> in
                    let status = GRPCStatus(code: .unimplemented, message: "Method '\(serviceName)/\(methodName)' not found.")
                    return context.writeAndFlush(self.wrapOutboundOut(.error(status, nil)))
                        .flatMapAlways { _ in context.close() }
                }
                return
            }
            self.logger[metadataKey: "grpc-method"] = "\(serviceName)/\(methodName)"
            self.connectionCtx = GRPCStreamConnectionContextImpl(
                eventLoop: context.eventLoop,
                initialRequestHeaders: headers,
                rpcHandler: rpcHandler,
                grpcMethodName: "\(serviceName)/\(methodName)"
            )
            self.connectionCtx!.handleStreamOpen()
        
        case .message(let messageIn):
            guard let connectionCtx = connectionCtx else {
                fatalError("Received message but there's no connection.")
            }
            let reqId = Self.requestIdCounter.get()
            _ = handleQueue.submit(on: context.eventLoop) { () -> EventLoopFuture<Void> in
                connectionCtx.handleMessage(messageIn)
                    .hop(to: context.eventLoop)
                    .flatMapAlways { (result: Result<GRPCMessageOut, Error>) -> EventLoopFuture<Void> in
                        switch result {
                        case .success(let messageOut):
                            return context.writeAndFlush(self.wrapOutboundOut(.message(messageOut, connectionCtx)))
                        case .failure(let error):
                            let status = (error as? GRPCStatus) ?? GRPCStatus(code: .unknown, message: "\(error.localizedDescription)")
                            return context.writeAndFlush(self.wrapOutboundOut(.error(status, connectionCtx)))
                        }
                    }
            }
        
        case .closeStream:
            guard let connectionCtx = connectionCtx else {
                fatalError("[\(Self.self)] received .closeStream but there's no active connection")
            }
            self.isConnectionClosed = true
            self.connectionCtx = nil
            // The RequestDecoder told us to close the stream.
            // We queue this to be run once the previous request is completed.
            _ = handleQueue.submit(on: context.eventLoop) { () -> EventLoopFuture<Void> in
                if let future = connectionCtx.handleStreamClose() {
                    return future.flatMapAlways { (result: Result<GRPCMessageOut, Error>) in
                        switch result {
                        case .failure(let error):
                            fatalError("Error: \(error)")
                        case .success(let messageOut):
                            return context.write(self.wrapOutboundOut(.message(messageOut, connectionCtx)))
                                .flatMapAlways { _ in context.close() }
                        }
                    }
                } else {
                    return context.write(self.wrapOutboundOut(.closeStream(trailers: HPACKHeaders())))
                        .flatMapAlways { _ in context.close() }
                }
            }
        }
    }
    
    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        context.fireUserInboundEventTriggered(event)
    }
}
