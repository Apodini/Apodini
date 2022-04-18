//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

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
    let errorForwarder: ErrorForwarder
    let delegate: Delegate<H>
    let endpointContext: GRPCEndpointContext
    
    required init(
        delegateFactory: DelegateFactory<H, GRPCInterfaceExporter>,
        strategy: AnyDecodingStrategy<GRPCMessageIn>,
        defaults: DefaultValueStore,
        errorForwarder: ErrorForwarder,
        endpointContext: GRPCEndpointContext
    ) {
        self.delegateFactory = delegateFactory
        self.decodingStrategy = strategy
        self.defaults = defaults
        self.errorForwarder = errorForwarder
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
        case .primitive, .enumTy, .refdMessageType:
            fatalError("Encountered invalid proto type: gRPC method return type must be a message. Got: \(endpointContext.endpointResponseType!)")
        case let .message(name: _, underlyingType, nestedOneofTypes: _, fields):
            if underlyingType != nil {
                // If there is an underlying type, we're handling a response message that is already a message type, so we simply encode that directly into the message payload
                return try ProtobufferEncoder().encode(responseContent)
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
