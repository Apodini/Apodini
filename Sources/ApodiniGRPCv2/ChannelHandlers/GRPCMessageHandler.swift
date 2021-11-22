import Foundation
import NIO
import NIOHTTP2
import NIOHPACK


class GRPCv2MessageHandler: ChannelInboundHandler {
    typealias InboundIn = Input
    typealias OutboundOut = Output
    
    enum Input {
        case openStream(HPACKHeaders)
        case message(GRPCv2MessageIn)
        case closeStream
    }
    
    // NOT an RPC response message!!! this is the wrapper type encapsulating the different kinds of responses which can come out of the `GRPCv2MessageHandler`.
    enum Output {
        /// A call resulted in an error.
        /// - parameter connectionCtx: The GRPCv2StreamConnectionContext belonging to this stream/channel (TODO terminology).
        ///         Nil if the channel encounters an error before a connection context was created.
        case error(GRPCv2Status, _ connectionCtx: GRPCv2StreamConnectionContextImpl?)
        
        /// A call resulted in a message
        case message(GRPCv2MessageOut, GRPCv2StreamConnectionContextImpl)
        case closeStream(trailers: HPACKHeaders, msg: String)
    }
    
    private /*unowned?*/ let server: GRPCv2Server
    
    private var connectionCtx: GRPCv2StreamConnectionContextImpl?
    private let handleQueue = LKEventLoopFutureBasedQueue()
    private var isConnectionClosed = false
    
    
    init(server: GRPCv2Server) {
        self.server = server
    }
    
    
    // TODO do we need to lock this? the write in the handler response future's whenComplete, so there might be a situation where we're still handling a message when another comes in. (and if that other message is faster and its whenComplete gets called first, we'd be writing handler responses in the incorrect order...)
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard !isConnectionClosed else {
            fatalError("[\(Self.self)] received data on channel, even though the connection should already be closed") // TODO simply ignore this?
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
                    let status = GRPCv2Status(code: .unimplemented, message: "Method '\(serviceName)/\(methodName)' not found.")
                    return context.writeAndFlush(self.wrapOutboundOut(.error(status, nil)))
                        .flatMapAlways { _ in context.close() }
                }
                return
            }
            self.connectionCtx = GRPCv2StreamConnectionContextImpl(
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
            _ = handleQueue.submit(on: context.eventLoop) { () -> EventLoopFuture<Void> in
                connectionCtx.handleMessage(messageIn)
                    .hop(to: context.eventLoop)
                    .flatMapAlways { (result: Result<GRPCv2MessageOut, Error>) -> EventLoopFuture<Void> in // TODO does using the connectionCtx/etc in here result in a retain cycle?
                        switch result {
                        case .success(let messageOut):
                            return context.writeAndFlush(self.wrapOutboundOut(.message(messageOut, connectionCtx)))
                        case .failure(let error):
                            return context.writeAndFlush(self.wrapOutboundOut(.error(GRPCv2Status(code: .unknown, message: "\(error)"), connectionCtx)))
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
            // We queue this to be run once the
            _ = handleQueue.submit(on: context.eventLoop) { () -> EventLoopFuture<Void> in
                connectionCtx.handleStreamClose()
                return context.write(self.wrapOutboundOut(.closeStream(trailers: HPACKHeaders(), msg: "connectionCtx.\(connectionCtx.grpcMethodName)")))
                    .flatMapAlways { _ in context.close() }
            }
        }
    }
    
    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        print(Self.self, #function, context, event)
        context.fireUserInboundEventTriggered(event)
    }
}

