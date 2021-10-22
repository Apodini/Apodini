import Apodini
import NIO
import NIOHTTP1
import NIOHTTP2
import NIOSSL
import NIOHPACK
import NIOWebSocket
import Foundation
import Logging // TODO add this as an explict dependency in the PAckage file!!!



struct ApodiniNetworkingError: Swift.Error {
    let message: String
}




public protocol WebSocketChannelHandler: ChannelInboundHandler where InboundIn == WebSocketFrame, OutboundOut == WebSocketFrame {}

class ErrorHandler: ChannelInboundHandler {
    typealias InboundIn = Never
    
    let msg: String
    
    init(msg: String) {
        self.msg = msg
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("\(Self.self)[msg: \(msg)][pid: \(ProcessInfo.processInfo.processIdentifier)] received error: \(error)")
        context.close(promise: nil)
    }
}




public final class HTTPServer {
    private struct ConfigStorage {
        let eventLoopGroup: EventLoopGroup
        let tlsConfiguration: TLSConfiguration?
        let enableHTTP2: Bool
        let address: BindAddress
        let logger: Logger
    }
    
    private enum Config {
        case app(Apodini.Application)
        case custom(ConfigStorage)
    }
    
    
    private let config: Config
    private let router: HTTPRouter
    
    private var channel: Channel?
    
    public var isRunning: Bool {
        return channel != nil // TODO is this good enough?
    }
    
    public var isCaseInsensitiveRoutingEnabled: Bool {
        get { router.isCaseInsensitiveRoutingEnabled }
        set { router.isCaseInsensitiveRoutingEnabled = newValue }
    }
    
    public var eventLoopGroup: EventLoopGroup {
        switch config {
        case .app(let app):
            return app.eventLoopGroup
        case .custom(let storage):
            return storage.eventLoopGroup
        }
    }
    
    public var tlsConfiguration: TLSConfiguration? {
        switch config {
        case .app(let app):
            return app.http.tlsConfiguration
        case .custom(let storage):
            return storage.tlsConfiguration
        }
    }
    
    public var enableHTTP2: Bool {
        switch config {
        case .app(let app):
            return app.http.supportVersions.contains(.two)
        case .custom(let storage):
            return storage.enableHTTP2
        }
    }
    
    public var address: BindAddress {
        switch config {
        case .app(let app):
            return app.http.address
        case .custom(let storage):
            return storage.address
        }
    }
    
    private var logger: Logger {
        switch config {
        case .app(let app):
            return app.logger
        case .custom(let storage):
            return storage.logger
        }
    }
    
    
    init(app: Apodini.Application) {
        //self.app = app
        self.config = .app(app)
        self.router = HTTPRouter(logger: app.logger)
    }
    
    
    internal var registeredRoutes: [HTTPRouter.Route] {
        return router.allRoutes
    }
    
    
    public init(
        eventLoopGroupProvider: NIOEventLoopGroupProvider,
        tlsConfiguration: TLSConfiguration? = nil,
        enableHTTP2: Bool = false,
        address: BindAddress,
        logger: Logger = .init(label: "\(HTTPServer.self)")
    ) {
        let eventLoopGroup: EventLoopGroup = {
            switch eventLoopGroupProvider {
            case .shared(let eventLoopGroup):
                return eventLoopGroup
            case .createNew:
                return MultiThreadedEventLoopGroup.init(numberOfThreads: System.coreCount)
            }
        }()
        self.config = .custom(.init(
            eventLoopGroup: eventLoopGroup,
            tlsConfiguration: tlsConfiguration,
            enableHTTP2: enableHTTP2,
            address: address,
            logger: logger
        ))
        self.router = HTTPRouter(logger: logger)
    }
    
    
    deinit {
        // TODO do we need to do something here?
        print("-[\(Self.self) \(#function)]")
    }
    
    
    public func start() throws {
        guard channel == nil else {
            throw ApodiniNetworkingError(message: "Cannot start already-running serve")
        }
        let bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelInitializer { [unowned self] (channel: Channel) -> EventLoopFuture<Void> in
                logger.notice("Configuring NIO channel pipeline. TLS: \(tlsConfiguration != nil), HTTP/2: \(enableHTTP2)")
                if let tlsConfig = tlsConfiguration {
                    precondition(tlsConfig.applicationProtocols.contains("h2"), "h2 not found in \(tlsConfig.applicationProtocols)")
                    let sslContext: NIOSSLContext
                    do {
                        sslContext = try NIOSSLContext(configuration: tlsConfig)
                    } catch {
                        logger.error("Unable to configure TLS: \(error)")
                        return channel.close(mode: .all)
                    }
                    let tlsHandler = NIOSSLServerHandler(context: sslContext)
                    return channel.pipeline.addHandler(tlsHandler).flatMap { () -> EventLoopFuture<Void> in
                        return channel.configureHTTP2SecureUpgrade { channel in
                            channel.addApodiniNetworkingHTTP2Handlers(responder: self)
                        } http1ChannelConfigurator: { channel in
                            channel.addApodiniNetworkingHTTP1Handlers(responder: self)
                        }
                    }.flatMapError { error in
                        return channel.eventLoop.makeFailedFuture(error)
                    }
                } else {
                    if enableHTTP2 {
                        // NOTE this doesn't make sense and (probably) doesn't work
                        return channel.addApodiniNetworkingHTTP2Handlers(responder: self)
                    } else {
                        return channel.addApodiniNetworkingHTTP1Handlers(responder: self)
                    }
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
        //    .childChannelOption(ChannelOptions.tcpOption(.tcp_nodelay), value: 1) // TODO is this the same as the line above?
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
        
        
        switch address {
        case .hostname(let hostname, let port):
            logger.info("Will bind to \(addressString)")
            channel = try bootstrap.bind(host: hostname, port: port).wait()
            //logger.info("Server starting on http\(tlsConfiguration != nil ? "s" : "")://\(hostname):\(port)")
            logger.info("Server starting on \(addressString)")
        case .unixDomainSocket(let path):
            logger.info("Will bind to \(addressString)")
            channel = try bootstrap.bind(unixDomainSocketPath: path).wait()
            //logger.info("Server starting on unix socket \(path)")
            logger.info("Server starting on \(addressString)")
        }
    }
    
    
    private var addressString: String {
        switch address {
        case .hostname(let hostname, let port):
            return "http\(tlsConfiguration != nil ? "s" : "")://\(hostname):\(port)"
        case .unixDomainSocket(let path):
            return "unix:\(path)" // TODO proper path!
        }
    }
    
    
    public func shutdown() throws {
        // TODO what to do here? Just call close?
        if let channel = channel {
            print("Will shut down NIO channel bound to \(addressString)")
            try channel.close(mode: .all).wait()
            self.channel = nil
            print("Did shut down NIO channel bound to \(addressString)")
        }
    }
}


/// A `HTTPResponder` is a type that can respond to HTTP requests.
public protocol HTTPResponder {
    /// Handle a request received by the server.
    /// - Note: The responder is responsible for converting errors thrown 
    func respond(to request: HTTPRequest) -> HTTPResponseConvertible
}


public struct DefaultHTTPRouteResponder: HTTPResponder {
    private let imp: (HTTPRequest) -> HTTPResponseConvertible
    
    public init(_ imp: @escaping (HTTPRequest) -> HTTPResponseConvertible) {
        self.imp = imp
    }
    
    public func respond(to request: HTTPRequest) -> HTTPResponseConvertible {
        return imp(request)
    }
}


/// A type on which HTTP routes can be registered
public protocol HTTPRoutesBuilder {
    func registerRoute(_ method: HTTPMethod, _ path: [HTTPPathComponent], handler: @escaping (HTTPRequest) -> HTTPResponseConvertible)
    func registerRoute(_ method: HTTPMethod, _ path: [HTTPPathComponent], responder: HTTPResponder)
}


public extension HTTPRoutesBuilder {
    func registerRoute(_ method: HTTPMethod, _ path: [HTTPPathComponent], handler: @escaping (HTTPRequest) throws -> HTTPResponseConvertible) {
        self.registerRoute(method, path) { request -> HTTPResponseConvertible in
            do {
                return try handler(request)
            } catch {
                return request.eventLoop.makeFailedFuture(error) as EventLoopFuture<HTTPResponse>
            }
        }
    }
    
    func registerRoute(_ method: HTTPMethod, _ path: [HTTPPathComponent], responder: HTTPResponder) {
        self.registerRoute(method, path) { request -> HTTPResponseConvertible in
            responder.respond(to: request)
        }
    }
}


extension HTTPServer: HTTPRoutesBuilder {
    public func registerRoute(_ method: HTTPMethod, _ path: [HTTPPathComponent], handler: @escaping (HTTPRequest) -> HTTPResponseConvertible) {
        router.add(HTTPRouter.Route(
            method: method,
            path: path,
            responder: DefaultHTTPRouteResponder(handler)
        ))
    }
}


extension HTTPServer: HTTPResponder {
    public func respond(to request: HTTPRequest) -> HTTPResponseConvertible {
        if let route = router.getRoute(for: request) {
            return route.responder
                .respond(to: request)
                .makeHTTPResponse(for: request)
        } else {
            return HTTPResponse(version: request.version, status: .notFound, headers: [:])
        }
    }
}



//public protocol WebSocketResponder {
//    func respond(to request: )
//}
//
//extension HTTPServer {
//    public func registerRoute(_ path: [String], handler)
//}



extension Channel {
    func addApodiniNetworkingHTTP2Handlers(responder: HTTPResponder) -> EventLoopFuture<Void> {
        let targetWindowSize: Int = numericCast(UInt16.max)
        return self.pipeline.addHandlers([
            NIOHTTP2Handler(mode: .server, initialSettings: [
                HTTP2Setting(parameter: .maxConcurrentStreams, value: 50), // 100?
                HTTP2Setting(parameter: .maxHeaderListSize, value: HPACKDecoder.defaultMaxHeaderListSize),
                HTTP2Setting(parameter: .maxFrameSize, value: 1 << 14), // swift-grpc uses 16384, which is 2^14? (ie 1<<14) ~~//2^!4?~~
                HTTP2Setting(parameter: .initialWindowSize, value: targetWindowSize)
            ]),
            // TODO do we want something in between here? swiftGRPC has an idle handler or smth like that, do we need that as well?
            HTTP2StreamMultiplexer(mode: .server, channel: self, targetWindowSize: targetWindowSize) { stream in
                stream.apodiniNetworkingInitializeHTTP2InboundStream(responder: responder)
            },
            ErrorHandler(msg: "http2.channel.error")
        ])
    }
    
    
    
    func apodiniNetworkingInitializeHTTP2InboundStream(responder: HTTPResponder) -> EventLoopFuture<Void> {
        return pipeline.addHandlers([
            HTTP2FramePayloadToHTTP1ServerCodec(),
            HTTPServerRequestDecoder(),
            HTTPServerResponseEncoder(),
            HTTPServerRequestHandler(responder: responder),
            ErrorHandler(msg: "http2.stream.error")
        ])
    }
    
    
    func addApodiniNetworkingHTTP1Handlers(responder: HTTPResponder) -> EventLoopFuture<Void> {
        var httpHandlers: [RemovableChannelHandler] = []
        let httpResponseEncoder = HTTPResponseEncoder()
        httpHandlers += [
            httpResponseEncoder,
            ByteToMessageHandler(HTTPRequestDecoder(leftOverBytesStrategy: .forwardBytes)),
            HTTPServerRequestDecoder(),
            HTTPServerResponseEncoder(),
        ]
        
        let httpRequestHandler = HTTPServerRequestHandler(responder: responder)
        
//        let webSocketsUpgrader = NIOWebSocketServerUpgrader(
//            shouldUpgrade: { (channel: Channel, reqHead: HTTPRequestHead) -> EventLoopFuture<HTTPHeaders?> in
//                print("Should upgrade?", channel, reqHead)
//                return channel.eventLoop.makeSucceededFuture([:])
//            },
//            upgradePipelineHandler: { (channel: Channel, reqHead: HTTPRequestHead) -> EventLoopFuture<Void> in
//                // TODO do we want to do something here?
//                return channel.eventLoop.makeSucceededVoidFuture()
//                //channel.pipeline.addHandler(WebSocketsRequestHandler())
//                //return .andAllComplete(httpHandlers.map { channel.pipeline.removeHandler($0) }, on: channel.eventLoop).flatMap {
//                    //channel.pipeline.removeHandler(httpRequestHandler)
//                //}
//            }
//        )
//
//        let upgrader = HTTPServerUpgradeHandler(
//            upgraders: [webSocketsUpgrader],
//            httpEncoder: httpResponseEncoder,
//            extraHTTPHandlers: (httpHandlers.appending(httpRequestHandler)).filter { $0 !== httpResponseEncoder },
//            upgradeCompletionHandler: { (context: ChannelHandlerContext) -> Void in print("upgrade complete!") }
//        )
        
        let upgrader = LKHTTPUpgradeHandler(
            handlersToRemoveOnWebSocketUpgrade: httpHandlers.appending(httpRequestHandler)
        )
        
        httpHandlers.append(contentsOf: [upgrader, httpRequestHandler] as [RemovableChannelHandler])
        
        return pipeline.addHandlers(httpHandlers).flatMap {
            self.pipeline.addHandler(ErrorHandler(msg: "HTTP1Pipeline"))
        }
        
//        return pipeline.addHandlers([
//            HTTPResponseEncoder(),
//            ByteToMessageHandler(HTTPRequestDecoder(leftOverBytesStrategy: .forwardBytes)),
//            HTTPServerRequestDecoder(),
//            HTTPServerResponseEncoder(),
//            HTTPServerRequestHandler(responder: responder),
//            // TODO add a HTTPServerUpgradeHandler ???
//        ]).flatMap {
//            self.pipeline.addHandler(ErrorHandler(msg: "configHTTP1Pipeline"))
//        }
    }
}