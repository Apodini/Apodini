import NIO
import NIOHTTP2


class HTTP2InboundStreamConfigurator: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTP2Frame.FramePayload
    typealias InboundOut = Never
    
    struct Configuration {
        enum MappingAction {
            /// Inserts NIO's `HTTP2FramePayloadToHTTP1ServerCodec` into the channel pipeline,
            /// and treats the stream as a HTTP2 connection serviced by a HTTP1 handler
            case forwardToHTTP1Handler(HTTPResponder)
            //case forwardAsHTTP2
            /// Allows whoever created this config mapping to provide a custom configurator function,
            /// which will be given the opportunity to configure the channel.
            case configureHTTP2Stream((Channel) -> EventLoopFuture<Void>)
        }
        
        struct Mapping {
            /// The Content-Type header values that cause this mapping to get selected
            let triggeringContentTypes: Set<HTTPMediaType>
            /// What this mapping should do
            let action: MappingAction
        }
        
        /// An array of mappings, i.e. instructions how incoming streams should be handled, based on their `Content-Type`, if available.
        /// In case multiple mappings in this array would match an incoming request, the first one wins.
        let mappings: [Mapping]
        /// The default action, which will be applied if no mapping matches the incoming request, or the request does not specify a `Content-Type` header
        let defaultAction: MappingAction
    }
    
    
    private enum State {
        /// The channel handler is ready to handle incoming HEADER frames
        case ready
        /// The channel handler has already received an incoming HEADER frame,
        /// and is currently applying the action taken in response to that frame.
        case applyingAction
    }
    
    private let configuration: Configuration
    private var state: State = .ready
    private var bufferedInput: [NIOAny] = []
    
    init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    
    private func fmtSel(_ caller: StaticString = #function) -> String {
        "-[\(Self.self) \(caller)]"
    }
    
    
    func channelActive(context: ChannelHandlerContext) {
        print(fmtSel())
        context.fireChannelActive()
    }
    
    
    private func applyMappingAction(_ action: Configuration.MappingAction, context: ChannelHandlerContext) {
        // TODO what if there's new incoming requests while all of this is taking place?
        switch action {
        case .forwardToHTTP1Handler(let responder):
//            context.pipeline.addHandlers([
//                HTTP2FramePayloadToHTTP1ServerCodec(),
//                HTTPServerRequestDecoder(),
//                HTTPServerResponseEncoder(),
//                HTTPServerRequestHandler(responder: responder)
//            ]).flatMap {
            context.channel.initializeHTTP2InboundStreamUsingHTTP2ToHTTP1Converter(responder: responder)
                .flatMap { context.pipeline.removeHandler(self) }
                //.whenSuccess { context.fireChannelRead(readData) }
        case .configureHTTP2Stream(let streamConfigurator):
            streamConfigurator(context.channel)
                .hop(to: context.eventLoop)
                .flatMap { context.pipeline.removeHandler(self) }
//                .whenSuccess {
//                    print("firing read for data that triggred the channel reconfig", readData)
//                    context.fireChannelRead(readData)
//                    context.fireChannelReadComplete()
//                }
        }
    }
    
    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        print(fmtSel(), data)
        let input = unwrapInboundIn(data)
        print("input: \(input)")
        
        switch state {
        case .ready:
            break
        case .applyingAction:
            // We're already applying an config action, so we just keep track of the data we've reveived in the meantime
            bufferedInput.append(data)
            return
        }
        
        switch input {
        case .headers(let headers):
            if let contentType = headers.headers[.contentType],
               let matchingMapping = configuration.mappings.first(where: { $0.triggeringContentTypes.contains(contentType) }) {
                self.bufferedInput.append(data)
                applyMappingAction(matchingMapping.action, context: context)
            } else {
                self.bufferedInput.append(data)
                applyMappingAction(configuration.defaultAction, context: context)
            }
            return
        default:
            fatalError("Unexpected input: \(input). This channel handler should only ever receive headers, and should have been removed from the pipeline by the time any other data are being received.")
        }
        
        switch input {
        case .data(let data): // data: HTTP2Frame.FramePayload.Data
            print("Got some raw data: \(data) (endStream: \(data.endStream))")
            switch data.data {
            case .byteBuffer(let buffer):
                print()
                print("As string:")
                print(buffer.getString(at: 0, length: buffer.writerIndex) as Any)
                print()
                print("As raw bytes:")
                print(buffer.getBytes(at: 0, length: buffer.writerIndex) as Any)
            case .fileRegion(let fileRegion):
                fatalError("Got unexpected FileRegion when expecting ByteBuffer: \(fileRegion)")
            }
        case .headers(let headers):
            print("Got some headers: \(headers) (endStream: \(headers.endStream))")
        case .priority(let priorityData): // HTTP2Frame.StreamPriorityData
            print("Got .priority: \(priorityData)")
        case .rstStream(let errorCode): // HTTP2ErrorCode
            print("Got .rstStream: \(errorCode)")
        case .settings(let settings): // HTTP2Frame.FramePayload.Settings
            print("Got .settings: \(settings)")
        case .pushPromise(let pushPromise): // HTTP2Frame.FramePayload.PushPromise
            print("Got .pushPromise: \(pushPromise)")
        case .ping(let pingData, let ack): // HTTP2PingData, Bool
            print("Got .ping(ack=\(ack)): \(pingData)")
        case .goAway(let lastStreamID, let errorCode, let opaqueData): // HTTP2StreamID, HTTP2ErrorCode, ByteBuffer?
            print("Got .goAway(lastStreamId: \(lastStreamID), errorCode: \(errorCode), opaqueData: \(opaqueData))")
        case .windowUpdate(let windowSizeIncrement): // Int
            print("Got .windowUpdate: \(windowSizeIncrement)")
        case .alternativeService(let origin, let field): // String?, ByteBuffer?
            print("Got .alternativeService(origin: \(origin), field: \(field)")
        case .origin(let origins): // [String]
            print("Got .origin(\(origins))")
        }
        //fatalError("TODO")
    }
    
    func channelReadComplete(context: ChannelHandlerContext) {
        print(fmtSel())
        fatalError()
    }
    
    
    func handlerRemoved(context: ChannelHandlerContext) {
        if !bufferedInput.isEmpty {
            for input in bufferedInput {
                context.fireChannelRead(input)
            }
            context.fireChannelReadComplete()
            bufferedInput.removeAll()
        }
    }
}

