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
//        /// A call produced an immediate error.
//        /// This case is only valid as the first response to come out of a handler.
//        /// As opposed to the other error case, this will send only trailing headers, and skip the initial HEADER and DATA frames.
//        /// - Note: This case will close the stream.
//        case immediateError(GRPCv2Status)
        
        /// A call resulted in an error.
        /// - parameter connectionCtx: The GRPCv2StreamConnectionContext belonging to this stream/channel (TODO terminology).
        ///         Nil if the channel encounters an error before a connection context was created.
        case error(GRPCv2Status, _ connectionCtx: GRPCv2StreamConnectionContext?)
        
        /// A call resulted in a message
        case message(GRPCv2MessageOut, GRPCv2StreamConnectionContext)
        case closeStream(trailers: HPACKHeaders, msg: String)
    }
    
    private /*unowned?*/ let server: GRPCv2Server
    
    private var connectionCtx: GRPCv2StreamConnectionContext?
    
    init(server: GRPCv2Server) {
        self.server = server
    }
    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        //let messageIn = unwrapInboundIn(data)
        print("-[\(Self.self) \(#function)]")
        
        switch unwrapInboundIn(data) {
        case .openStream(let headers):
            precondition(connectionCtx == nil, "Received .openStream even though we alrready have a connection up and running.")
            let splitPath = headers[.pathPseudoHeader]!.split(separator: "/")
            let (serviceName, methodName) = (String(splitPath[0]), String(splitPath[1]))
            guard let rpcHandler = server.makeStreamRPCHandler(toService: serviceName, method: methodName) else {
                // A nil return value indicates that the method does not exist.
                // gRPC says we have to handle this by responding w/ the corresponding status code
                print("Attempted to open channel to non-existing method '\(serviceName)/\(methodName)'")
                context.write(
                    wrapOutboundOut(.error(GRPCv2Status(code: .unimplemented, message: "Method '\(serviceName)/\(methodName)' not found."), nil)),
                    promise: nil
                )
                context.close(mode: .all, promise: nil)
                return
            }
            self.connectionCtx = GRPCv2StreamConnectionContext(
                eventLoop: context.eventLoop,
                initialRequestHeaders: headers,
                rpcHandler: rpcHandler
            )
            self.connectionCtx!.tmp_method = headers[.pathPseudoHeader]!
            self.connectionCtx!.handleStreamOpen()
        case .message(let messageIn):
            guard let connectionCtx = connectionCtx else {
                fatalError("Received message but there's no connection.")
            }
            connectionCtx
                .handle(message: messageIn)
                .hop(to: context.eventLoop)
                .whenComplete { (result: Result<GRPCv2MessageOut, Error>) in
                    switch result {
                    case .success(let messageOut):
                        // TODO to flush or not to flush???
                        context.writeAndFlush(self.wrapOutboundOut(.message(messageOut, connectionCtx)), promise: nil)
                    case .failure(let error):
                        print("WRITING ERROR RESPONSE")
                        context.writeAndFlush(self.wrapOutboundOut(.error(GRPCv2Status(code: .unknown, message: "\(error)"), connectionCtx)), promise: nil) // TODO a) get the error code from the handler, b) dont leak the whole error???
                    }
                }
        case .closeStream:
            print("Received .closeStream on \(connectionCtx?.tmp_method)")
            // TODO do we need to do something here?
            self.connectionCtx?.handleStreamClose()
            context.write(wrapOutboundOut(.closeStream(trailers: HPACKHeaders(), msg: "connectionCtx.\(connectionCtx?.tmp_method)")), promise: nil)
            self.connectionCtx = nil
            break
        }
    }
    
    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        print(Self.self, #function, context, event)
        context.fireUserInboundEventTriggered(event)
    }
}

