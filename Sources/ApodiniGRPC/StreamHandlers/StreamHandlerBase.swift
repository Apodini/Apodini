import Apodini
import ApodiniExtension
import ApodiniUtils
import NIO
import ProtobufferCoding
import Foundation


/// Base class for all gRPC stream handlers.
/// This class implements the interface common to all stream handlers and provides useful helper functions, e.g. for encoding responses.
class StreamRPCHandlerBase<H: Handler>: GRPCStreamRPCHandler {
    let delegateFactory: DelegateFactory<H, GRPCInterfaceExporter>
    let decodingStrategy: AnyDecodingStrategy<GRPCMessageIn>
    let defaults: DefaultValueStore
    let delegate: Delegate<H>
    let endpointContext: GRPCEndpointContext
    
    required init(
        delegateFactory: DelegateFactory<H, GRPCInterfaceExporter>,
        strategy: AnyDecodingStrategy<GRPCMessageIn>,
        defaults: DefaultValueStore,
        endpointContext: GRPCEndpointContext
    ) {
        self.delegateFactory = delegateFactory
        self.decodingStrategy = strategy
        self.defaults = defaults
        self.delegate = delegateFactory.instance()
        self.endpointContext = endpointContext
    }
    
    func handleStreamOpen(context: GRPCStreamConnectionContext) {}
    
    func handleStreamClose(context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut>? {
        nil
    }
    
    func handle(message: GRPCMessageIn, context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut> {
        fatalError("Abstract. Implement in subclass.")
    }
    
    
    func encodeResponseIntoProtoMessage(_ responseContent: H.Response.Content) throws -> ByteBuffer {
        switch self.endpointContext.endpointResponseType! {
        case .builtinEmptyType, .primitive, .enumTy, .refdMessageType:
            fatalError()
        case let .compositeMessage(name: _, underlyingType, nestedOneofTypes: _, fields):
            if let underlyingType = underlyingType {
                precondition(underlyingType == type(of: responseContent))
                // If there is an underlying type, we're handling a response message that is already a message type, so we simply encode that directly into the message payload
                let payload = try ProtobufferEncoder().encode(responseContent)
                return payload
                //return .singleMessage(headers: headers, payload: payload, closeStream: true)
            } else {
                // If there is no underlying type, the handler returns something primitive which we'll have to manually wrap into a message
                precondition(fields.count == 1)
                return try ProtobufferEncoder().encode(responseContent, asField: fields[0])
            }
        }
    }
}


extension StreamRPCHandlerBase {
    struct AbortTransformer: ResultTransformer {
        func handle(error: ApodiniError) -> ErrorHandlingStrategy<Apodini.Response<H.Response.Content>, Error> {
            .abort(error)
        }
        
        func transform(input: Apodini.Response<H.Response.Content>) -> Apodini.Response<H.Response.Content> {
            input
        }
    }
}

