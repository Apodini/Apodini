import Apodini
import ApodiniNetworking
import ApodiniExtension
import NIO
import NIOHTTP2
import NIOHPACK
import ApodiniUtils
import Foundation


enum GRPCv2MessageEncoding: String {
    case proto
    case json
}


// Note: the fact that it exists, and that we could recognise it, does not mean that we support it
enum GRPCv2MessageCompressionType: RawRepresentable, HTTPHeaderFieldValueCodable {
    case identity
    case gzip
    case deflate
    case snappy
    case custom(String)
    
    init(rawValue: String) {
        switch rawValue {
        case Self.identity.rawValue:
            self = .identity
        case Self.gzip.rawValue:
            self = .gzip
        case Self.deflate.rawValue:
            self = .deflate
        case Self.snappy.rawValue:
            self = .snappy
        default:
            self = .custom(rawValue)
        }
    }
    
    init(httpHeaderFieldValue value: String) {
        self.init(rawValue: value)
    }
    
    func encodeToHTTPHeaderFieldValue() -> String {
        rawValue
    }
    
    var rawValue: String {
        switch self {
        case .identity:
            return "identity"
        case .gzip:
            return "gzip"
        case .deflate:
            return "deflate"
        case .snappy:
            return "snappy"
        case .custom(let value):
            return value
        }
    }
}



extension AnyHTTPHeaderName {
    static let gRPCEncoding = HTTPHeaderName<GRPCv2MessageCompressionType>("grpc-encoding")
}





/// The NIO ChannelHandler responsible for decoding incoming HTTP/2 streams into GRPCMessages.
/// Implementing this via a dedicated channel handler (as opposed to simply registering routes on the HTTP server and relying on NIO's
/// HTTP2ToHTTP1CodecConverter thing) gives us much greater control over how the channel is managed.
/// This is required in order to accurately match the gRPC behaviour as defined in the spec.
/// (One example: NIO's HTTP2-to-HTTP1 thing drops all incoming PING frames, whereas gRPC expects us to return them unchanged)
class TODO_remove {}




extension AnyHTTPHeaderName {
    // TODO move this to ApodiniNetworking!?!!
    static let pathPseudoHeader = HTTPHeaderName<String>(":path")
    static let statusPseudoHeader = HTTPHeaderName<HTTPResponseStatus>(":status")
}


extension HTTPResponseStatus: HTTPHeaderFieldValueCodable {
    public init?(httpHeaderFieldValue value: String) {
        if let intValue = Int(value) {
            self.init(statusCode: intValue)
        } else {
            return nil
        }
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        String(code)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        hasher.combine(reasonPhrase)
    }
}


struct GRPCv2MessageIn: RequestBasis, CustomStringConvertible, CustomDebugStringConvertible {
    let remoteAddress: SocketAddress?
    /// The HTTP/2 headers sent with the initial HTTP request that initiated this stream
    let requestHeaders: HPACKHeaders
    /// The payload of this message
    let payload: ByteBuffer
    /// The event loop on which this message was received
    let eventLoop: EventLoop // TODO remove this? We have the context which gets passed along everywhere...
    
    
    var targetServiceName: String {
        String(requestHeaders[.pathPseudoHeader]!.split(separator: "/")[0])
    }
    
    var targetMethodName: String {
        String(requestHeaders[.pathPseudoHeader]!.split(separator: "/")[1])
    }
    
    var serviceAndMethodName: (service: String, method: String) {
        let splitPath = requestHeaders[.pathPseudoHeader]!.split(separator: "/")
        return (String(splitPath[0]), String(splitPath[1]))
    }
    
    var description: String {
        ///"\(Self.self)(headers: \()"
        var retval = "\(Self.self)("
        retval.append("headers: ")
        retval.append("\(requestHeaders.map { "\($0.name)=\($0.value)" })")
        retval.append(", payload: \(payload)")
        retval.append(")")
        return retval
    }
    
    var debugDescription: String {
        description
    }
    
    
    var information: InformationSet {
        [] // TODO?
    }
}


struct GRPCv2MessageOut_OLD {
    var headers: HPACKHeaders
    var payload: ByteBuffer
    var shouldCloseStream: Bool // TODO remove this in favour of a somewhat smarter approach
    
//    var resultsInStreamClosure: Bool {
//
//    }
}


/// The result of an RPC invocation.
/// Note that the differentiation here between `singleMessage` and `stream` is not necessarily equivalent to gRPC's differentiation between unary and stream-based methods.
/// `singleMessage` is intended for situations where a call results in one response message, regardless of whether or not the connection is to be kept open or closed.
/// (e.g.: unary connections, bidirectional connections where every client request gets answered with exactly one server response, etc.)
/// `stream` is intended for situations where a single client request may result in multiple responses.
enum GRPCv2MessageOut {
    typealias Stream = BufferedStream<(ByteBuffer, closeStream: Bool)>
    /// A single gRPC message.
    /// - parameter headers: The headers to be sent with this message. Note that headers will only be written once to a HTTP/2 stream.
    /// - parameter payload: The gRPC message data to be written.
    /// - parameter closeStream: Whether after sending this message, the connection to the client (i.e. the underlying HTTP/2 stream) should be closed.
    case singleMessage(headers: HPACKHeaders, payload: ByteBuffer, closeStream: Bool)
    /// A RPC resulted in a stream-based response.
    case stream(HPACKHeaders, Stream)
    
    var headers: HPACKHeaders {
        switch self {
        case .singleMessage(let headers, _, _), .stream(let headers, _):
            return headers
        }
    }
}


class BufferedStream<Element> {
    typealias ObserverFn = (Element) -> Void
    
    private let lock = NSLock()
    private var buffer = CircularBuffer<Element>()
    private var observer: ObserverFn?
    private var isClosed = false
    
    init() {}
    
    func setObserver(_ observerFn: ObserverFn?) {
        lock.withLock {
            if let newObserver = observerFn {
                precondition(self.observer == nil, "Cannot set multiple observers on stream")
                for element in buffer {
                    newObserver(element)
                }
                buffer.removeAll()
                if !isClosed {
                    // Only actually set the observer if the stream is still open.
                    self.observer = newObserver
                }
            } else {
                self.observer = nil
            }
        }
    }
    
    func write(_ element: Element) {
        write(element, closeStream: false)
    }
    
    func writeAndClose(_ element: Element) {
        write(element, closeStream: true)
    }
    
    private func write(_ element: Element, closeStream: Bool) {
        lock.withLock {
            precondition(!isClosed, "Cannot write to closed stream")
            if let observer = observer {
                precondition(buffer.isEmpty) // If we have an observer, we expect the buffer to be empty
                observer(element)
            } else {
                buffer.append(element)
            }
            if closeStream {
                self.isClosed = true
                self.observer = nil
            }
        }
    }
}



class GRPCv2RequestDecoder: ChannelInboundHandler {
    typealias InboundIn = HTTP2Frame.FramePayload
    typealias InboundOut = GRPCv2MessageHandler.Input
    
    /// Context of a messahe currently being collected from the stream
    private class MessageCollectionContext: Hashable {
        let expectedPayloadSize: Int
        let compression: GRPCv2MessageCompressionType?
        var buffer = ByteBuffer() {
            didSet { assert(buffer.writerIndex <= expectedPayloadSize) }
        }
        
        init(expectedPayloadSize: Int, compression: GRPCv2MessageCompressionType?) {
            self.expectedPayloadSize = expectedPayloadSize
            self.compression = compression
        }
        
        var numMissingPayloadBytes: Int {
            expectedPayloadSize - buffer.writerIndex
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(self))
        }
        
        static func == (lhs: MessageCollectionContext, rhs: MessageCollectionContext) -> Bool {
            ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
        }
    }
    
    private enum State: Equatable {
        case ready
        // TODO
        /// - parameter numMissingPayloadBytes: The number of bytes still missing from the message payload.
        ///     This should only be set when a message is spread across multiple DATA frames, to keep track of the message boundaries.
        //case handlingStream(HPACKHeaders, Box<ByteBuffer>, numMissingPayloadBytes: Int? = nil)
        /// - parameter initialHeaders: The headers received with the initial request that opened the stream.
        /// - parameter ctx: Context object containing infrmation about the (gRPC) message currently being collected from the stream.
        ///         This will only be set to a nonnull value while reading a message which is spread across multiple DATA frames.
        case handlingStream(initialHeaders: HPACKHeaders, messageCollectionCtx: MessageCollectionContext?)
    }
    
    
    private var state: State = .ready
    
    
    private func fmtSel(_ caller: StaticString = #function) -> String {
        "-[\(Self.self) \(caller)]"
    }
    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let input = unwrapInboundIn(data)
        print(fmtSel())
        
        switch input {
        case .data(let dataFrame): // data: HTTP2Frame.FramePayload.Data
            //print("Got a DATA frame: \(dataFrame) (endStream: \(dataFrame.endStream))")
            defer {
                precondition(dataFrame.endStream == (state == .ready))
            }
            switch dataFrame.data {
            case .byteBuffer(let buffer):
                print("Got a DATA frame")
//                print()
//                print("As string:")
//                print(buffer.getString(at: 0, length: buffer.writerIndex) as Any)
//                print()
//                print("As raw bytes:")
//                print(buffer.getBytes(at: 0, length: buffer.writerIndex) as Any)
                switch state {
                case .ready:
                    fatalError("Invalid state: .ready when receiving DATA frame.")
                case let .handlingStream(initialHeaders, messageCollectionCtx):
                    //case let .handlingStream(headers, messageCollectionCtx):
                    var dataFrameDataBuffer = buffer
//                    if dataFrameDataBuffer.readableBytes == 0 && dataFrame.endStream {
//                        print("Reveived empty DATA frame w/ END_STREAM flag set")
//                        self.state = .ready
//                        return
//                    }
                    if dataFrameDataBuffer.readableBytes == 0 && dataFrame.endStream {
                        context.fireChannelRead(self.wrapInboundOut(.closeStream))
                        self.state = .ready
                        return
                    }
                    let didReadForPrevMessage: Bool
                    if let messageCollectionCtx = messageCollectionCtx {
                        if dataFrameDataBuffer.readableBytes >= messageCollectionCtx.numMissingPayloadBytes {
                            // The DATA frame contains more bytes than what we're missing, so we just consume the ones belonging to us, turn that into a message, and move on
                            let remainingBytes = dataFrameDataBuffer.readSlice(length: messageCollectionCtx.numMissingPayloadBytes)!
                            messageCollectionCtx.buffer.writeImmutableBuffer(remainingBytes)
                            print("found a message")
                            context.fireChannelRead(wrapInboundOut(.message(GRPCv2MessageIn(
                                remoteAddress: context.channel.remoteAddress,
                                requestHeaders: initialHeaders,
                                payload: messageCollectionCtx.buffer,
                                eventLoop: context.eventLoop
                            ))))
//                            if dataFrame.endStream {
//                                print("Setting state to .ready bc we received a END_STREAM flag[a]")
//                                //state = .ready
//                            } else {
//                                //state = .handlingStream(headers, Box(ByteBuffer()), numMissingPayloadBytes: nil) // TODO make sure this deallocates the box!
//                                state = .handlingStream(initialHeaders: initialHeaders, messageCollectionCtx: nil) // TODO make sure this deallocates the prev ctx!
//                            }
                            state = .handlingStream(initialHeaders: initialHeaders, messageCollectionCtx: nil) // TODO make sure this deallocates the prev ctx!
                            didReadForPrevMessage = true
                        } else {
                            // The DATA frame contains fewer bytes than what we're looking for, so we just add all of them and wait for the next frame
                            let numBytesInDataFrame = dataFrameDataBuffer.readableBytes
                            messageCollectionCtx.buffer.writeBuffer(&dataFrameDataBuffer)
                            //payloadBufferRef.value.writeBuffer(&dataFrameDataBuffer)
                            precondition(!dataFrame.endStream)
                            ////state = .handlingStream(headers, payloadBufferRef, numMissingPayloadBytes: numMissingPayloadBytes - numBytesInDataFrame)
                            //state = .handlingStream(initialHeaders: initialHeaders, messageCollectionCtx: messageCollectionCtx)
                            return
                        }
                    } else {
                        // TODO remove this, really just here to make sure there isnt a bug!
                        didReadForPrevMessage = false
                    }
                    // At this point, we've either read all of the previous payload's remaining bytes, or there was no previous payload in this DATA frame.
                    // Either way, we should now be at the beginning of a new frame
//                    if dataFrame.endStream && dataFrameDataBuffer.readableBytes == 0 {
//                        // we received an empty DATA frame with the END_STREAM flag set.
//                        // This means that we should end the stream
//                        context.fireChannelRead(wrapInboundOut(.closeStream))
//                        state = .ready
//                        return
//                    }
                    precondition(dataFrameDataBuffer.readableBytes >= 0 && !didReadForPrevMessage, "unexpectedly found empty DATA frame...")
                    while dataFrameDataBuffer.readableBytes > 0 {
                        precondition(state == .handlingStream(initialHeaders: initialHeaders, messageCollectionCtx: nil))
//                        let (payloadData, numMissingBytes) = decodeMessagePayload(from: &dataFrameDataBuffer, messageCompression: nil)
//                        precondition(numMissingBytes >= 0)
//                        precondition(numMissingBytes > 0, implies: dataFrameDataBuffer.readableBytes == 0)
//                        if numMissingBytes == 0 {
//                            let message = GRPCv2MessageIn(requestHeaders: initialHeaders, payload: payloadData, eventLoop: context.eventLoop)
//                            context.fireChannelRead(wrapInboundOut(message))
//                            state = .handlingStream(initialHeaders, Box(ByteBuffer()), numMissingPayloadBytes: nil)
//                        } else {
//                            precondition(!dataFrame.endStream)
//                            state = .handlingStream(initialHeaders, Box(payloadData), numMissingPayloadBytes: numMissingBytes)
//                        }
                        let messageCtx = decodeMessagePayload(from: &dataFrameDataBuffer, headers: initialHeaders)
                        precondition(messageCtx.numMissingPayloadBytes >= 0) // Make sure we haven't read more than we want to
                        precondition(messageCtx.numMissingPayloadBytes > 0, implies: dataFrameDataBuffer.readableBytes == 0) // If there's payload byted missing, we must've reached the end of the current DATA frame
                        if messageCtx.numMissingPayloadBytes == 0 {
                            let messageIn = GRPCv2MessageIn(
                                remoteAddress: context.channel.remoteAddress,
                                requestHeaders: initialHeaders,
                                payload: messageCtx.buffer,
                                eventLoop: context.eventLoop
                            )
                            print("found a message")
                            context.fireChannelRead(wrapInboundOut(.message(messageIn)))
                            state = .handlingStream(initialHeaders: initialHeaders, messageCollectionCtx: nil)
                        } else {
                            // There's data missing
                            precondition(!dataFrame.endStream)
                            state = .handlingStream(initialHeaders: initialHeaders, messageCollectionCtx: messageCtx)
                        }
                    }
                    if dataFrame.endStream {
                        print("Setting state to .ready bc we received a END_STREAM flag[b]")
                        state = .ready
                    }
                }
            case .fileRegion(let fileRegion):
                fatalError("Got unexpected FileRegion when expecting ByteBuffer: \(fileRegion)")
            }
        case .headers(let headers):
            //print("Got some headers: \(headers) (endStream: \(headers.endStream))")
            switch state {
            case .ready:
                //let messageBodyRef = Box(ByteBuffer())
                //self.state = .handlingStream(headers.headers, messageBodyRef)
                self.state = .handlingStream(initialHeaders: headers.headers, messageCollectionCtx: nil)
                context.fireChannelRead(wrapInboundOut(.openStream(headers.headers)))
            case .handlingStream:
                // TODO this might in fact be a valid state after all, HEADERS frames can also be sent at the end of a request,
                // although the gRPC docs don't mention this so idk maybe they don't use that.
                // (They do use it for responses, but that doesn't apply here...)
                fatalError("Invalid state: received HEADERS frame when handling a stream.")
            }
        case .priority(let priorityData): // HTTP2Frame.StreamPriorityData
            fatalError("Got .priority: \(priorityData)")
        case .rstStream(let errorCode): // HTTP2ErrorCode
            print("RECEIVED RST_STREAM (w/ error code \(errorCode). CLOSING CHANNEL")
            context.close(mode: .all, promise: nil)
            //fatalError("Got .rstStream: \(errorCode)")
        case .settings(let settings): // HTTP2Frame.FramePayload.Settings
            fatalError("Got .settings: \(settings)")
        case .pushPromise(let pushPromise): // HTTP2Frame.FramePayload.PushPromise
            fatalError("Got .pushPromise: \(pushPromise)")
        case .ping(let pingData, let ack): // HTTP2PingData, Bool
            fatalError("Got .ping(ack=\(ack)): \(pingData)")
        case .goAway(let lastStreamID, let errorCode, let opaqueData): // HTTP2StreamID, HTTP2ErrorCode, ByteBuffer?
            fatalError("Got .goAway(lastStreamId: \(lastStreamID), errorCode: \(errorCode), opaqueData: \(opaqueData))")
        case .windowUpdate(let windowSizeIncrement): // Int
            fatalError("Got .windowUpdate: \(windowSizeIncrement)")
        case .alternativeService(let origin, let field): // String?, ByteBuffer?
            fatalError("Got .alternativeService(origin: \(origin), field: \(field)")
        case .origin(let origins): // [String]
            fatalError("Got .origin(\(origins))")
        }
    }
    
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print(fmtSel(), error)
        context.fireErrorCaught(error)
    }
    
    
    
    /// Decodes a gRPC message payload from the specified buffer.
    /// - Returns: A tuple consisting of the read data, as well as the number of bytes missing from the payload (this is the case if the payload is spread over multiple DATA frames).
    /// - Note: This function operates on the assumption that the buffer's current reader index does in fact point to the beginning of a gRPC message.
    //private func decodeMessagePayload(from buffer: inout ByteBuffer, messageCompression: GRPCv2MessageCompressionType?) -> (ByteBuffer, missingBytes: Int) {
    private func decodeMessagePayload(from buffer: inout ByteBuffer, headers: HPACKHeaders) -> MessageCollectionContext {
        let messageCompression = headers[.gRPCEncoding]
        precondition(messageCompression == nil, "Compression not yet supported")
        guard buffer.readableBytes >= 5 else {
            fatalError("Invalid input: buffers must consist of at least five bytes")
        }
        let isCompressed: Bool = buffer.readInteger(as: UInt8.self)! == 1
        let messageLength = Int(buffer.readInteger(endianness: .big, as: UInt32.self)!)
        let messageCtx = MessageCollectionContext(
            expectedPayloadSize: messageLength,
            compression: isCompressed ? messageCompression : nil
        )
        let payload = buffer.readSlice(length: min(messageLength, buffer.readableBytes))!
        messageCtx.buffer.writeImmutableBuffer(payload)
//        //print("payload", payload)
////        fatalError()
//        //return (payload, messageLength - payload.writerIndex)
//        return MessageCollectionContext(expectedPayloadSize: <#T##Int#>, compression: <#T##GRPCv2MessageCompressionType?#>)
        return messageCtx
    }
}






/// An open GRPC stream over which messages are sent
class GRPCv2StreamConnectionContext {
    let eventLoop: EventLoop
    let initialRequestHeaders: HPACKHeaders
//    private var requestsQueue = CircularBuffer<GRPCv2MessageIn>()
    fileprivate let rpcHandler: GRPCv2StreamRPCHandler
    private var lastMessageResponseFuture: EventLoopFuture<Void>?
    private var numQueuedHandlerCalls = 0
    fileprivate var tmp_method: String = ""
    
    fileprivate init(eventLoop: EventLoop, initialRequestHeaders: HPACKHeaders, rpcHandler: GRPCv2StreamRPCHandler) {
        self.eventLoop = eventLoop
        self.initialRequestHeaders = initialRequestHeaders
        self.rpcHandler = rpcHandler
    }
    
    
//    fileprivate func addMessageToQueue(_ message: GRPCv2MessageIn) {
//        requestsQueue.append(message)
//    }
    
    fileprivate func handleStreamOpen() {
        rpcHandler.handleStreamOpen(context: self)
    }
    
    fileprivate func handleStreamClose() {
        rpcHandler.handleStreamClose(context: self)
    }
    
    
    fileprivate func handle(message: GRPCv2MessageIn) -> EventLoopFuture<GRPCv2MessageOut> {
        // TODO does any of this need to be thread-safe? looking especially at the numQueuedHandlerCalls thing...
        defer {
            self.lastMessageResponseFuture!.whenComplete { [unowned self] _ in
                self.numQueuedHandlerCalls -= 1
                precondition(self.numQueuedHandlerCalls >= 0)
                if self.numQueuedHandlerCalls == 0 {
                    self.lastMessageResponseFuture = nil
                }
            }
        }
        precondition((self.numQueuedHandlerCalls == 0) == (self.lastMessageResponseFuture == nil))
        guard let lastFuture = lastMessageResponseFuture else {
            precondition(numQueuedHandlerCalls == 0)
            let promise = eventLoop.makePromise(of: Void.self)
            self.numQueuedHandlerCalls += 1
            self.lastMessageResponseFuture = promise.futureResult
            let rpcFuture = rpcHandler.handle(message: message, context: self)
            rpcFuture.whenComplete { _ in
                promise.succeed(())
            }
            return rpcFuture
        }
        let retvalPromise = eventLoop.makePromise(of: GRPCv2MessageOut.self)
        self.numQueuedHandlerCalls += 1
        self.lastMessageResponseFuture = lastFuture.flatMapAlways { [unowned self] _ -> EventLoopFuture<Void> in
            let promise = eventLoop.makePromise(of: Void.self)
            let rpcFuture = rpcHandler.handle(message: message, context: self)
            rpcFuture.cascade(to: retvalPromise)
            rpcFuture.whenComplete { _ in
                promise.succeed(())
            }
            return promise.futureResult
        }
        return retvalPromise.futureResult
        //self.lastMessageResponsePromise = eventLoop.makePromise(of: Void.self)
    }
}


protocol GRPCv2StreamRPCHandler: AnyObject {
    func handleStreamOpen(context: GRPCv2StreamConnectionContext)
    func handleStreamClose(context: GRPCv2StreamConnectionContext)
    func handle(message: GRPCv2MessageIn, context: GRPCv2StreamConnectionContext) -> EventLoopFuture<GRPCv2MessageOut>
}


//protocol GRPCv2StreamConnectionContext_ImplReqs: GRPCv2StreamConnectionContext {
//    func handle(request message: GRPCv2MessageIn) -> EventLoopFuture<GRPCv2MessageOut>
//}
//
//
//typealias GRPCv2StreamConnectionContextType = GRPCv2StreamConnectionContext & GRPCv2StreamConnectionContext_ImplReqs


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



class GRPCv2ResponseEncoder: ChannelOutboundHandler {
    typealias OutboundIn = GRPCv2MessageHandler.Output
    typealias OutboundOut = HTTP2Frame.FramePayload
    
    
    private var didWriteHeadersFrame = false
    
    
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        //precondition(!didWriteHeadersFrame) // TODO we can remove this variable!
        let response = unwrapOutboundIn(data)
        
        switch response {
        case let .error(status, connectionCtx):
            //precondition(!didWriteHeaderFrame, "Invalid state. Received \(response), but a HEADER frame was already written previously")
            let trailersFrame = HTTP2Frame.FramePayload.headers(HTTP2Frame.FramePayload.Headers(
                headers: HPACKHeaders {
                    status.encode(into: &$0)
                }.applyingHTTP2Validations(),
                priorityData: nil, // <#T##HTTP2Frame.StreamPriorityData?#>
                endStream: true,
                paddingBytes: nil
            ))
            context.write(wrapOutboundOut(trailersFrame))
                .flatMap {
                    connectionCtx?.handleStreamClose()
                    return context.close()
                }
                .cascade(to: promise)
            return
        case let .message(message, connectionCtx): // TODO rename message here to response or smth like that?
            if !didWriteHeadersFrame {
                var headers = message.headers
                headers[.statusPseudoHeader] = .ok
                headers.applyHTTP2Validations()
                let headersFrame = HTTP2Frame.FramePayload.headers(HTTP2Frame.FramePayload.Headers(
                    headers: headers,
                    priorityData: nil, //<#T##HTTP2Frame.StreamPriorityData?#>,
                    endStream: false,
                    paddingBytes: nil // TODO?
                ))
                print("Writing HEADERS frame", headersFrame, connectionCtx.tmp_method)
                context.writeAndFlush(wrapOutboundOut(headersFrame), promise: nil)
                didWriteHeadersFrame = true
            }
            switch message {
            case let .singleMessage(_, payload, closeStream):
                // TODO this one will resolve the promise directly after writing one message, regardless of whether the stream is kept open or not, whereas the one in the other branch below will only resolve the promise once the stream is closed.! FIX!!!!!
                writeLengthPrefixedMessage(payload, closeStream: closeStream, connectionContext: connectionCtx, channelHandlerContext: context, promise: promise)
                break
            case .stream(_, let stream):
                stream.setObserver { (payload: ByteBuffer, closeStream: Bool) in // TODO does this introduce a retain cycle?
                    print("GRPC STREAM EVENT", payload.readableBytes, closeStream)
                    context.eventLoop.execute {
                        self.writeLengthPrefixedMessage(payload, closeStream: closeStream, connectionContext: connectionCtx, channelHandlerContext: context, promise: promise)
                    }
                }
            }
            do {
//                let messageLength = message.payload.writerIndex
//                precondition(messageLength <= numericCast(UInt32.max))
//                var buffer = ByteBufferAllocator().buffer(capacity: message.payload.writerIndex + 5)
//                buffer.writeInteger(UInt8(0)) // indicate that we have no compression. TODO add compression?
//                buffer.writeInteger(UInt32(messageLength), endianness: .big, as: UInt32.self)
//                buffer.writeImmutableBuffer(message.payload)
//                let dataFrame = HTTP2Frame.FramePayload.data(.init(
//                    data: .byteBuffer(buffer),
//                    endStream: false,
//                    paddingBytes: nil
//                ))
//                print("Writing DATA frame", dataFrame)
//                //context.write(self.wrapOutboundOut(dataFrame), promise: message.shouldCloseStream ? nil : promise)
//                context.writeAndFlush(wrapOutboundOut(dataFrame)).whenComplete { _ in
//                    print("Writing DATA Frame done (prom: \(promise))")
//                    if !message.shouldCloseStream {
//                        promise?.succeed(())
//                    }
//                }
            }
        case .closeStream(let trailers, let msg):
//            let trailers = HTTP2Frame.FramePayload.headers(.init(
//                headers: HPACKHeaders {
//                    GRPCv2Status(code: .ok, message: nil).encode(into: &$0)
//                }.applyingHTTP2Validations(),
//                priorityData: nil, // <#T##HTTP2Frame.StreamPriorityData?#>
//                endStream: true,
//                paddingBytes: nil
//            ))
//            print("trailers: \(trailers)")
//            print("Writing TRAILERS frame")
//            context.writeAndFlush(wrapOutboundOut(trailers)).whenComplete { result in
//                print("WROTE TRAILERS", result)
//                context.close(mode: .all).whenComplete { result in
//                    print("CHANNEL CLOSE", result)
//                    promise?.succeed(())
//                }
//            }
            writeTrailers(context: context, msg: msg).cascade(to: promise)
//            if message.shouldCloseStream {
//                let trailers = HTTP2Frame.FramePayload.headers(.init(
//                    headers: HPACKHeaders {
//                        GRPCv2Status(code: .ok, message: nil).encode(into: &$0)
//                    }.applyingHTTP2Validations(),
//                    priorityData: nil, // <#T##HTTP2Frame.StreamPriorityData?#>
//                    endStream: true,
//                    paddingBytes: nil
//                ))
//                print("trailers: \(trailers)")
//                print("Writing TRAILERS frame")
//                connectionCtx.handleStreamClose()
//                context.writeAndFlush(self.wrapOutboundOut(trailers), promise: promise)
//            }
        }
        
//        if !didWriteHeaderFrame {
//            didWriteHeaderFrame = true
//            var headers = messageOut.headers
//            headers[.statusPseudoHeader] = .ok
//            headers.validateForHTTP2()
//            let headerFrame = HTTP2Frame.FramePayload.headers(.init(
//                headers: headers,
//                priorityData: nil,
//                endStream: false,
//                paddingBytes: nil
//            ))
//            print("Writing HEADER frame", Thread.current.name, headerFrame)
//            context.write(wrapOutboundOut(headerFrame), promise: nil)
//        }
//
//        do {
//            let messageLength = messageOut.payload.writerIndex
//            precondition(messageLength <= numericCast(UInt32.max))
//            var buffer = ByteBufferAllocator().buffer(capacity: messageOut.payload.writerIndex + 5)
//            buffer.writeInteger(UInt8(0)) // indicate that we have no compression. TODO add compression?
//            buffer.writeInteger(UInt32(messageLength), endianness: .big, as: UInt32.self)
//            buffer.writeImmutableBuffer(messageOut.payload)
//            let dataFrame = HTTP2Frame.FramePayload.data(.init(
//                data: .byteBuffer(buffer),
//                endStream: false,
//                paddingBytes: nil
//            ))
//            print("Writing DATA frame", Thread.current.name, dataFrame)
//            context.write(self.wrapOutboundOut(dataFrame), promise: nil)
//        }
//
//        let trailers = HTTP2Frame.FramePayload.headers(.init(
//            headers: HPACKHeaders {
//                //$0[.statusPseudoHeader] = .ok
//                //$0[.contentType] = .gRPC(.proto)
//                $0[.grpcStatus] = 0
//                $0.add(name: "grpc-message", value: "thisisthemessage")
//            }.validatedForHTTP2(),
//            priorityData: nil, // <#T##HTTP2Frame.StreamPriorityData?#>
//            endStream: messageOut.shouldCloseStream,
//            paddingBytes: nil
//        ))
//        print("trailers: \(trailers)")
//        print("Writing TRAILERS frame")
//        context.writeAndFlush(self.wrapOutboundOut(trailers), promise: promise)
    }
    
    
    private func writeLengthPrefixedMessage(
        _ payload: ByteBuffer,
        closeStream: Bool,
        connectionContext: GRPCv2StreamConnectionContext,
        channelHandlerContext: ChannelHandlerContext,
        promise: EventLoopPromise<Void>?
    ) {
        let messageLength = payload.writerIndex
        precondition(messageLength <= numericCast(UInt32.max))
        var buffer = ByteBufferAllocator().buffer(capacity: payload.writerIndex + 5)
        buffer.writeInteger(UInt8(0)) // indicate that we have no compression. TODO add compression?
        buffer.writeInteger(UInt32(messageLength), endianness: .big, as: UInt32.self)
        buffer.writeImmutableBuffer(payload)
        let dataFrame = HTTP2Frame.FramePayload.data(.init(
            data: .byteBuffer(buffer),
            endStream: false,
            paddingBytes: nil
        ))
        print("Writing DATA frame for \(connectionContext.tmp_method)", dataFrame)
        //context.write(self.wrapOutboundOut(dataFrame), promise: message.shouldCloseStream ? nil : promise)
        channelHandlerContext.writeAndFlush(wrapOutboundOut(dataFrame)).whenComplete { _ in
            print("Writing DATA Frame done (prom: \(promise))")
            if !closeStream {
                promise?.succeed(())
            }
        }
        
        if closeStream {
            writeTrailers(context: channelHandlerContext, msg: connectionContext.tmp_method).cascade(to: promise)
//            let trailers = HTTP2Frame.FramePayload.headers(.init(
//                headers: HPACKHeaders {
//                    GRPCv2Status(code: .ok, message: nil).encode(into: &$0)
//                }.applyingHTTP2Validations(),
//                priorityData: nil, // <#T##HTTP2Frame.StreamPriorityData?#>
//                endStream: true,
//                paddingBytes: nil
//            ))
//            print("trailers: \(trailers)")
//            print("Writing TRAILERS frame")
//            connectionContext.handleStreamClose()
//            //channelHandlerContext.writeAndFlush(self.wrapOutboundOut(trailers), promise: promise)
//            channelHandlerContext.write(self.wrapOutboundOut(trailers)).whenComplete { _ in
////                //channelHandlerContext.close(mode: .all, promise: promise)
////                channelHandlerContext.close(mode: .all).whenComplete { result in
////                    print(result)
////                    fatalError()
////                }
//                print("Wrote stream-closing Trailers frame")
//                channelHandlerContext.close(mode: .all).cascade(to: promise)
//            }
        }
    }
    
    
    private func writeTrailers(context: ChannelHandlerContext, msg: String) -> EventLoopFuture<Void> {
        let trailers = HTTP2Frame.FramePayload.headers(.init(
            headers: HPACKHeaders {
                GRPCv2Status(code: .ok, message: nil).encode(into: &$0)
            }.applyingHTTP2Validations(),
            priorityData: nil, // <#T##HTTP2Frame.StreamPriorityData?#>
            endStream: true,
            paddingBytes: nil
        ))
        print("trailers: \(trailers)")
        print("Writing TRAILERS frame for \(msg)")
        //channelHandlerContext.writeAndFlush(self.wrapOutboundOut(trailers), promise: promise)
        return context.writeAndFlush(self.wrapOutboundOut(trailers))
//            .flatMap {
//                context.close(mode: .all)
//                    .flatMapAlways { result in
//                        print(result)
//                        fatalError()
//                    }
//            }
    }
    
    
    func close(context: ChannelHandlerContext, mode: CloseMode, promise: EventLoopPromise<Void>?) {
        print("CLOSE")
        context.close(mode: mode, promise: promise)
    }
    
    func triggerUserOutboundEvent(context: ChannelHandlerContext, event: Any, promise: EventLoopPromise<Void>?) {
        print(Self.self, #function, context, event)
        context.triggerUserOutboundEvent(event, promise: promise)
    }
}
