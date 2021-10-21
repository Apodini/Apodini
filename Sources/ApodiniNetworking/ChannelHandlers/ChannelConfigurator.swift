import NIO
import NIOHTTP1
import NIOHTTP2


class LKNIOHTTP2ChannelConfigurator: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTP2Frame.FramePayload
    typealias InboundOut = HTTP2Frame.FramePayload
    
    
    func channelRegistered(context: ChannelHandlerContext) {
        print("\(Self.self).\(#function)")
        context.fireChannelRegistered()
    }
    
    
    func channelUnregistered(context: ChannelHandlerContext) {
        print("\(Self.self).\(#function)")
        context.fireChannelUnregistered()
    }
    
    
    func channelActive(context: ChannelHandlerContext) {
        print("\(Self.self).\(#function)")
        context.fireChannelActive()
    }
    
    
    func channelInactive(context: ChannelHandlerContext) {
        print("\(Self.self).\(#function)")
        context.fireChannelInactive()
    }
    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        print("\(Self.self).\(#function)", data)
        let framePayload: HTTP2Frame.FramePayload = unwrapInboundIn(data)
        switch framePayload {
        case .headers(let headers):
            fatalError("\(headers)")
        
        case .data(let data):
            fatalError("\(data)")
        case .priority(let streamPriorityData):
            fatalError("\(streamPriorityData)")
        case .rstStream(let errorCode as HTTP2ErrorCode):
            fatalError("\(errorCode)")
        case .settings(let settings):
            fatalError("\(settings)")
        case .pushPromise(let pushPromise):
            fatalError("\(pushPromise)")
        case .ping(let pingData, let ack):
            fatalError("\(pingData), ack: \(ack)")
        case .goAway(let lastStreamID, let errorCode, let opaqueData):
            fatalError("\(lastStreamID), \(errorCode), \(opaqueData)")
        case .windowUpdate(let windowSizeIncrement):
            fatalError("\(windowSizeIncrement)")
        case .alternativeService(let origin, let field):
            fatalError("\(origin), \(field)")
        case .origin(let origin):
            fatalError("\(origin)")
        }
        
//        do {
//            try context.channel.pipeline.syncOperations.addHandlers([
//            ])
//        } catch {
//            context.fireErrorCaught(error)
//        }
        
        //context.fireChannelRead(data)
    }
    
    
    func channelReadComplete(context: ChannelHandlerContext) {
        print("\(Self.self).\(#function)")
        context.fireChannelReadComplete()
    }
    
    
    func channelWritabilityChanged(context: ChannelHandlerContext) {
        print("\(Self.self).\(#function)")
        context.fireChannelWritabilityChanged()
    }
    
    
    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        print("\(Self.self).\(#function)", event)
        context.fireUserInboundEventTriggered(event)
    }
    
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("\(Self.self).\(#function)", error)
        context.fireErrorCaught(error)
    }
}
