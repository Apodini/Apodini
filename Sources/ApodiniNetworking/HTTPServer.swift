import Apodini
import NIO
import NIOHTTP1
import NIOHTTP2
import NIOSSL
import NIOHPACK
import Foundation
import Logging // TODO add this as an explict dependency in the PAckage file!!!



struct ApodiniNetworkingError: Swift.Error {
    let message: String
}


private class HTTPServer: NIO.ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        print(#function)
        fatalError()
    }
    
    
    func channelInactive(context: ChannelHandlerContext) {
        print(#function)
        fatalError()
    }
}



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




public final class LKNIOBasedHTTPServer {
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
    private let router: LKHTTPRouter
    
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
        self.router = LKHTTPRouter(logger: app.logger)
    }
    
    
    internal var registeredRoutes: [LKHTTPRouter.Route] {
        return router.allRoutes
    }
    
    
    public init(
        eventLoopGroupProvider: NIOEventLoopGroupProvider,
        tlsConfiguration: TLSConfiguration? = nil,
        enableHTTP2: Bool = false,
        address: BindAddress,
        logger: Logger = .init(label: "\(LKNIOBasedHTTPServer.self)")
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
        self.router = LKHTTPRouter(logger: logger)
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
                        print("about to configure HTTP2SecureUpgrade")
                        return channel.configureHTTP2SecureUpgrade { channel in
                            channel.lk_addApodiniNetworkingHTTP2Handlers(responder: self)
                        } http1ChannelConfigurator: { channel in
                            channel.lk_addApodiniNetworkingHTTP1Handlers(responder: self)
                        }
                    }.flatMapError { error in
                        print("ERROR", error)
                        return channel.eventLoop.makeFailedFuture(error)
                    }
                } else {
                    if enableHTTP2 {
                        // NOTE this doesn't make sense and (probably) doesn't work
                        return channel.lk_addApodiniNetworkingHTTP2Handlers(responder: self)
                    } else {
                        return channel.lk_addApodiniNetworkingHTTP1Handlers(responder: self)
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




/// A `HTTPRouteResponder` is a type that can respond to HTTP requests.
public protocol LKHTTPRouteResponder {
    /// Handle a request received by the server.
    /// - Note: The responder is responsible for converting errors thrown 
    func respond(to request: LKHTTPRequest) -> LKHTTPResponseConvertible
}


public struct LKDefaultHTTPRouteResponder: LKHTTPRouteResponder {
    private let imp: (LKHTTPRequest) -> LKHTTPResponseConvertible
    
    public init(_ imp: @escaping (LKHTTPRequest) -> LKHTTPResponseConvertible) {
        self.imp = imp
    }
    
    public func respond(to request: LKHTTPRequest) -> LKHTTPResponseConvertible {
        return imp(request)
    }
}


public protocol LKHTTPRouteBuilder {
    func registerRoute(_ method: HTTPMethod, _ path: [LKHTTPPathComponent], handler: @escaping (LKHTTPRequest) -> LKHTTPResponseConvertible)
    func registerRoute(_ method: HTTPMethod, _ path: [LKHTTPPathComponent], responder: LKHTTPRouteResponder)
}


public extension LKHTTPRouteBuilder {
    func registerRoute(_ method: HTTPMethod, _ path: [LKHTTPPathComponent], handler: @escaping (LKHTTPRequest) throws -> LKHTTPResponseConvertible) {
        self.registerRoute(method, path) { request -> LKHTTPResponseConvertible in
            do {
                return try handler(request)
            } catch {
                return request.eventLoop.makeFailedFuture(error) as EventLoopFuture<LKHTTPResponse>
            }
        }
    }
    
    func registerRoute(_ method: HTTPMethod, _ path: [LKHTTPPathComponent], responder: LKHTTPRouteResponder) {
        self.registerRoute(method, path) { request -> LKHTTPResponseConvertible in
            responder.respond(to: request)
        }
    }
}


extension LKNIOBasedHTTPServer: LKHTTPRouteBuilder {
    public func registerRoute(_ method: HTTPMethod, _ path: [LKHTTPPathComponent], handler: @escaping (LKHTTPRequest) -> LKHTTPResponseConvertible) {
        router.add(LKHTTPRouter.Route(
            method: method,
            path: path,
            responder: LKDefaultHTTPRouteResponder(handler)
        ))
    }
}


extension LKNIOBasedHTTPServer: LKHTTPRouteResponder {
    public func respond(to request: LKHTTPRequest) -> LKHTTPResponseConvertible {
        if let route = router.getRoute(for: request) {
            return route.responder
                .respond(to: request)
                .makeHTTPResponse(for: request)
        } else {
            return LKHTTPResponse(version: request.version, status: .notFound, headers: [:])
        }
    }
}



extension Channel {
    func lk_addApodiniNetworkingHTTP2Handlers(responder: LKHTTPRouteResponder) -> EventLoopFuture<Void> {
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
                stream.lk_apodiniNetworkingInitializeHTTP2InboundStream(responder: responder)
            },
            ErrorHandler(msg: "http2.channel.error")
        ])
    }
    
    
    
    func lk_apodiniNetworkingInitializeHTTP2InboundStream(responder: LKHTTPRouteResponder) -> EventLoopFuture<Void> {
        return pipeline.addHandlers([
            HTTP2FramePayloadToHTTP1ServerCodec(),
            LKHTTPServerRequestDecoder(),
            LKHTTPServerResponseEncoder(),
            LKHTTPServerRequestHandler(responder: responder),
            ErrorHandler(msg: "http2.stream.error")
        ])
    }
    
    
    func lk_addApodiniNetworkingHTTP1Handlers(responder: LKHTTPRouteResponder) -> EventLoopFuture<Void> {
        return pipeline.addHandlers([
            HTTPResponseEncoder(),
            ByteToMessageHandler(HTTPRequestDecoder(leftOverBytesStrategy: .forwardBytes)),
            LKHTTPServerRequestDecoder(),
            LKHTTPServerResponseEncoder(),
            LKHTTPServerRequestHandler(responder: responder),
            // TODO add a HTTPServerUpgradeHandler ???
        ]).flatMap {
            self.pipeline.addHandler(ErrorHandler(msg: "configHTTP1Pipeline"))
        }
    }
}
