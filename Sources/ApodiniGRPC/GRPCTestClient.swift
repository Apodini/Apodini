//import NIO
//import NIOHTTP2
//import NIOSSL
//import NIOHPACK
//import NIOPosix
//import ProtobufferCoding
//import ApodiniNetworking
//import ApodiniNetworkingHTTPSupport
//import ApodiniUtils
//
//
//#if DEBUG || RELEASE_TESTING
//
//
//
//class GRPCClient {
//    private let eventLoopGroupProvider: NIOEventLoopGroupProvider
//    private var eventLoopGroup: EventLoopGroup
//    
//    
//    init(eventLoopGroupProvider: NIOEventLoopGroupProvider) {
//        self.eventLoopGroupProvider = eventLoopGroupProvider
//        switch eventLoopGroupProvider {
//        case .shared(let group):
//            self.eventLoopGroup = group
//        case .createNew:
//            self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//        }
//    }
//    
//    
//    
//    deinit {
//        switch eventLoopGroupProvider {
//        case .shared:
//            break
//        case .createNew:
//            try! self.eventLoopGroup.syncShutdownGracefully()
//        }
//    }
//    
//    
//    func start() {
//        let bootstrap = ClientBootstrap(group: eventLoopGroup)
//            .channelInitializer { channel in
//                
//            }
//    }
//}
//
//
//
//private class ErrorHandler: ChannelInboundHandler, ChannelOutboundHandler {
//    typealias InboundIn = Never
//    typealias OutboundOut = Never
//    
//    let msg: String
//    
//    init(msg: String) {
//        self.msg = msg
//    }
//    
//    func errorCaught(context: ChannelHandlerContext, error: Error) {
//        print("\(Self.self)[msg: \(msg)][pid: \(ProcessInfo.processInfo.processIdentifier)] received error: \(error)")
//        context.close(promise: nil)
//    }
//}
//
//
//
//extension Channel {
//    func configureForGRPCClient() -> EventLoopFuture<Void> {
//        let targetWindowSize: Int = numericCast(UInt16.max)
//        return self.pipeline.addHandlers([
//            NIOHTTP2Handler(mode: .server, initialSettings: [
//                HTTP2Setting(parameter: .maxConcurrentStreams, value: 50),
//                HTTP2Setting(parameter: .maxHeaderListSize, value: HPACKDecoder.defaultMaxHeaderListSize),
//                HTTP2Setting(parameter: .maxFrameSize, value: 1 << 14),
//                HTTP2Setting(parameter: .initialWindowSize, value: targetWindowSize)
//            ]),
//            HTTP2StreamMultiplexer(mode: .server, channel: self, targetWindowSize: targetWindowSize) { stream in
//                stream.pipeline.addHandlers([
//                    GRPCClientChannelHandler
//                ])
//            },
//            ErrorHandler(msg: "http2.channel.error")
//        ])
//    }
//}
//
//
//
//
//
//
//class GRPCClientRequestEncoder: ChannelOutboundHandler {
//    typealias OutboundIn = GRPCClientChannelHandler.OutboundOut
//    typealias OutboundOut = HTTP2Frame.FramePayload
//    
//    
//    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
//        let message = unwrapOutboundIn(data)
//    }
//}
//
//
//
//class GRPCClientChannelHandler: ChannelInboundHandler {
//    typealias InboundIn = GRPCMessageOut // we're a client here, so the terminology is reversed!!!
//    typealias OutboundOut = GRPCMessageIn
//    
//    func channelActive(context: ChannelHandlerContext) {
//        let request = GRPCMessageIn(
//            remoteAddress: nil,
//            requestHeaders: HPACKHeaders {
//                $0[.contentType] = .gRPC(.proto)
//            },
//            payload: <#T##ByteBuffer#>
//        )
//    }
//}
//
//
//
//
//class GRPCClientResponseDecoder: ChannelInboundHandler {
//    typealias InboundIn = HTTP2Frame.FramePayload
//    typealias InboundOut = GRPCClientChannelHandler.InboundIn
//}
//
//
//#endif // DEBUG || RELEASE_TESTING
