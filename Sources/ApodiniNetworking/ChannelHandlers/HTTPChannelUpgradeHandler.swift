import NIO
import NIOHTTP1
import NIOHTTP2
import NIOWebSocket
import WebSocketKit
import Logging


/// A removable channel handler which can be used to upgrade HTTP1 requests to a different protocol.
/// Heavily insired by Vapor's equivalent of this
class LKHTTPUpgradeHandler: ChannelInboundHandler, ChannelOutboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTPRequest
    typealias InboundOut = HTTPRequest
    typealias OutboundIn = HTTPResponse
    typealias OutboundOut = HTTPResponse
    
    private enum State: Equatable {
        case ready
        case pendingWebSocketUpgrade(HTTPRequest)
    }
    
    
    private let handlersToRemoveOnWebSocketUpgrade: [RemovableChannelHandler]
    private var state: State = .ready
    private var bufferedData: [NIOAny] = []
    private let logger = Logger(label: "HTTPUpgradeHandler")
    
    
    init(handlersToRemoveOnWebSocketUpgrade: [RemovableChannelHandler]) {
        self.handlersToRemoveOnWebSocketUpgrade = handlersToRemoveOnWebSocketUpgrade
    }
    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        switch state {
        case .pendingWebSocketUpgrade:
            logger.notice("Received further data while handling upgrade. Saving to buffer.")
            // We've already initiated the upgrade process, but are receiving more data. Cache that until the upgrade is complete.
            self.bufferedData.append(data)
            return
        case .ready:
            break
        }
        
        precondition(state == .ready)
        precondition(bufferedData.isEmpty)
        
        let request = unwrapInboundIn(data)
        
        guard request.headers[.connection].contains(.upgrade) else {
            logger.notice("Received non-upgrade request while in ready state")
            // NOTE it might be a good idea to use this as an opportunity to remove ourselves from the pipeline?
            context.fireChannelRead(data)
            return
        }
        
        let upgradeHeaderValues = request.headers[.upgrade]
        
        if upgradeHeaderValues.contains(.webSocket) {
            state = .pendingWebSocketUpgrade(request)
            logger.notice("Received WebSocket upgrade request")
            context.fireChannelRead(data)
        } else {
            fatalError("Received unexpected Upgrade handler (value: '\(upgradeHeaderValues)')")
        }
    }
    
    
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        switch state {
        case .ready:
            // Received some outbound data, but we're not in the process of switching protocols, so we just forward it
            logger.notice("Received outbound data while in ready state (i.e. while not upgrading. Simply forwarding to next handler")
            context.write(data, promise: promise)
            return
        case .pendingWebSocketUpgrade(let request):
            logger.notice("Received outbound data while handling WebSocket upgrade")
            let response = unwrapOutboundIn(data)
            guard let upgradingResponse = response as? HTTPUpgradingResponse, upgradingResponse.status == .switchingProtocols else {
                // We initiated the upgrade process, but now aren't getting the expected response.
                // Just pipe this through and hope for the best
                state = .ready
                context.write(data, promise: promise)
                // Note: as above, this might be a good point to remove ourselves from the pipeline.
                // Also, it might be necessary to write back the buffered data at this point.
                logger.notice("Response is not the expected upgrade response. Handling as normal")
                return
            }
            switch upgradingResponse.upgrade {
            case let .webSocket(maxFrameSize, shouldUpgrade, onUpgrade):
                let webSocketUpgrader = NIOWebSocketServerUpgrader(
                    maxFrameSize: maxFrameSize,
                    automaticErrorHandling: false,
                    shouldUpgrade: { _, _ in shouldUpgrade() },
                    upgradePipelineHandler: { channel, _ in
                        WebSocket.server(on: channel, onUpgrade: onUpgrade)
                    }
                )
                
                let head = HTTPRequestHead(
                    version: request.version,
                    method: request.method,
                    uri: request.url.stringValue,
                    headers: request.headers
                )
                
                logger.notice("About to build upgrade response")
                webSocketUpgrader.buildUpgradeResponse(channel: context.channel, upgradeRequest: head, initialResponseHeaders: [:])
                    .map { headers in
                        self.logger.notice("Mapping headers")
                        response.headers = headers
                        context.write(self.wrapOutboundOut(response), promise: promise)
                    }
                    .flatMap { () -> EventLoopFuture<Void> in
                        self.logger.notice("Removing handlers")
                        let handlers: [RemovableChannelHandler] = [self] + self.handlersToRemoveOnWebSocketUpgrade
                        return .andAllComplete(handlers.map { handler in
                            return context.pipeline.removeHandler(handler)
                        }, on: context.eventLoop)
                    }
                    .flatMap { () -> EventLoopFuture<Void> in
                        self.logger.notice("Calling upgrader.upgrade")
                        return webSocketUpgrader.upgrade(context: context, upgradeRequest: head)
                    }
                    .cascadeFailure(to: promise)
            }
        }
    }
    
    
    func handlerRemoved(context: ChannelHandlerContext) {
        logger.notice("\(#function)")
        if !bufferedData.isEmpty {
            for data in bufferedData {
                context.fireChannelRead(data)
            }
            bufferedData.removeAll()
            context.fireChannelReadComplete()
        }
    }
}
