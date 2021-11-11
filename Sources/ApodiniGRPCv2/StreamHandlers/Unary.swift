import Apodini
import ApodiniExtension
import NIO
import NIOHPACK
import ApodiniUtils
import Foundation




class UnaryRPCHandler<H: Handler>: StreamRPCHandlerBase<H> {
    override func handle(message: GRPCv2MessageIn, context: GRPCv2StreamConnectionContext) -> EventLoopFuture<GRPCv2MessageOut> {
        let responseFuture: EventLoopFuture<Apodini.Response<H.Response.Content>> = decodingStrategy
            .decodeRequest(from: message, with: message, with: context.eventLoop)
            .insertDefaults(with: defaults)
            .cache()
            .evaluate(on: delegate)
        return responseFuture.map { (response: Apodini.Response<H.Response.Content>) -> GRPCv2MessageOut in
            let headers = HPACKHeaders {
                $0[.contentType] = .gRPC(.proto)
            }
            guard let responseContent = response.content else {
                return .singleMessage(headers: headers, payload: ByteBuffer(), closeStream: true) // TODO keep open based on handler type?
            }
//            switch self.endpointContext.endpointResponseType! {
//            case .builtinEmptyType, .primitive, .enumTy, .refdMessageType:
//                fatalError()
//            case let .compositeMessage(name: _, underlyingType, nestedOneofTypes: _, fields):
//                if let underlyingType = underlyingType {
//                    precondition(underlyingType == type(of: responseContent))
//                    // If there is an underlying type, we're handling a response message that is already a message type, so we simply encode that directly into the message payload
//                    let payload = try! LKProtobufferEncoder().encode(responseContent)
//                    return .singleMessage(headers: headers, payload: payload, closeStream: true)
//                } else {
//                    // If there is no underlying type, the handler returns something primitive which we'll have to manually wrap into a message
//                    precondition(fields.count == 1)
//                    let fieldNumber = fields[0].fieldNumber
//                    let dstBufferRef = Box(ByteBuffer())
//                    let encoder = _LKProtobufferEncoder(codingPath: [], dstBufferRef: dstBufferRef)
//                    var keyedEncoder = encoder.container(keyedBy: FakeCodingKey.self)
//                    try! keyedEncoder.encode(responseContent, forKey: .init(intValue: fieldNumber))
//                    return .singleMessage(headers: headers, payload: dstBufferRef.value, closeStream: true)
//                }
//            }
            return .singleMessage(
                headers: headers,
                payload: try! self.encodeResponseIntoProtoMessage(responseContent),
                closeStream: true
            )
        }
    }
}



//class _UnaryStreamRPCHandler<H: Handler>: GRPCv2StreamRPCHandler {
//    private let delegateFactory: DelegateFactory<H, GRPCv2InterfaceExporter>
//    private let decodingStrategy: AnyDecodingStrategy<GRPCv2MessageIn>
//    private let defaults: DefaultValueStore
//    private let delegate: Delegate<H>
//    private let endpointContext: GRPCv2EndpointContext
//
//    init(
//        delegateFactory: DelegateFactory<H, GRPCv2InterfaceExporter>,
//        strategy: AnyDecodingStrategy<GRPCv2MessageIn>,
//        defaults: DefaultValueStore,
//        endpointContext: GRPCv2EndpointContext
//    ) {
//        self.delegateFactory = delegateFactory
//        self.decodingStrategy = strategy
//        self.defaults = defaults
//        self.delegate = delegateFactory.instance()
//        self.endpointContext = endpointContext
//    }
//
//    func handleStreamOpen(context: GRPCv2StreamConnectionContext) {
//        print(#function, context)
//    }
//
//    func handleStreamClose(context: GRPCv2StreamConnectionContext) {
//        print(#function, context)
//    }
//
//    func handle(message: GRPCv2MessageIn, context: GRPCv2StreamConnectionContext) -> EventLoopFuture<GRPCv2MessageOut> {
//        print(Self.self, #function, message.serviceAndMethodName)
//        switch endpointContext.communicationalPattern {
//        case .requestResponse:
//            return handleUnary(message: message, context: context)
//        case .clientSideStream:
//            fatalError()
//        case .serviceSideStream:
//            return handleServiceSideStream(message: message, context: context)
//        case .bidirectionalStream:
//            fatalError()
//        }
//
//    }
//
//
//    private func handleUnary(message: GRPCv2MessageIn, context: GRPCv2StreamConnectionContext) -> EventLoopFuture<GRPCv2MessageOut> {
//    }
//
//    private func handleClientSideStream(message: GRPCv2MessageIn, context: GRPCv2StreamConnectionContext) -> EventLoopFuture<GRPCv2MessageOut> {
//
//    }
//
//    private func handleServiceSideStream(message: GRPCv2MessageIn, context: GRPCv2StreamConnectionContext) -> EventLoopFuture<GRPCv2MessageOut> {
//        let responsesStream = GRPCv2MessageOut.Stream()
//        let abortAnyError = AbortTransformer<H>()
//        return [message]
//            .asAsyncSequence
//            .decode(using: decodingStrategy, with: context.eventLoop)
//            .insertDefaults(with: defaults)
//            .cache()
//            .subscribe(to: delegate)
//            .evaluate(on: delegate)
//            .transform(using: abortAnyError)
//            .cancelIf { $0.connectionEffect == .close }
//            .firstFutureAndForEach(
//                on: context.eventLoop,
//                objectsHandler: { (response: Apodini.Response<H.Response.Content>) -> Void in
////                    defer {
////                        if response.connectionEffect == .close {
////                            // TODO presumably this would get turned into an empty DATA frame (followed by the trailers)?
////                            // can we somehow skip the empty frame and directly translate this into sending trailers? (maybe by adding support for nil payloads?)
////                            responsesStream.writeAndClose((ByteBuffer(), closeStream: true))
////                        }
////                    }
//                    do {
//                        if let content = response.content {
//                            let buffer = try LKProtobufferEncoder().encode(content)
//                            responsesStream.write((buffer, closeStream: response.connectionEffect == .close))
//                        } else {
//                            // TODO presumably this would get turned into an empty DATA frame (followed by the trailers)?
//                            // can we somehow skip the empty frame and directly translate this into sending trailers? (maybe by adding support for nil payloads?)
//                            responsesStream.write((ByteBuffer(), closeStream: response.connectionEffect == .close))
//                        }
//                    } catch {
//                        // Error encoding the response data
//                        print("Error encoding part of response: \(error)")
//                    }
//                }
//            )
//            .map { firstResponse -> GRPCv2MessageOut in
//                return GRPCv2MessageOut.stream(
//                    HPACKHeaders {
//                        $0[.contentType] = .gRPC(.proto)
//                    },
//                    responsesStream
//                )
//            }
//    }
//
//    private func handleBidirectionalStream(message: GRPCv2MessageIn, context: GRPCv2StreamConnectionContext) -> EventLoopFuture<GRPCv2MessageOut> {
//
//    }
//
//}
//
