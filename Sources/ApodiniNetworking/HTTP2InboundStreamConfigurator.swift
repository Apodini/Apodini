//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import NIO
import NIOHTTP2
import struct Apodini.Hostname


class HTTP2InboundStreamConfigurator: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTP2Frame.FramePayload
    typealias InboundOut = Never
    
    struct Configuration {
        enum MappingAction {
            /// Inserts NIO's `HTTP2FramePayloadToHTTP1ServerCodec` into the channel pipeline,
            /// and treats the stream as a HTTP2 connection serviced by a HTTP1 handler
            case forwardToHTTP1Handler(any HTTPResponder)
            //case forwardAsHTTP2
            /// Allows whoever created this config mapping to provide a custom configurator function,
            /// which will be given the opportunity to configure the channel.
            case configureHTTP2Stream((any Channel) -> EventLoopFuture<Void>)
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
    private let hostname: Hostname
    private let isTLSEnabled: Bool
    private var state: State = .ready
    private var bufferedInput: [NIOAny] = []
    
    init(configuration: Configuration, hostname: Hostname, isTLSEnabled: Bool) {
        self.configuration = configuration
        self.hostname = hostname
        self.isTLSEnabled = isTLSEnabled
    }
    
    
    private func applyMappingAction(_ action: Configuration.MappingAction, context: ChannelHandlerContext) {
        switch action {
        case .forwardToHTTP1Handler(let responder):
            _ = context.channel.initializeHTTP2InboundStreamUsingHTTP2ToHTTP1Converter(
                hostname: hostname,
                isTLSEnabled: isTLSEnabled,
                responder: responder
            )
                .flatMap { context.pipeline.removeHandler(self) }
        case .configureHTTP2Stream(let streamConfigurator):
            _ = streamConfigurator(context.channel)
                .hop(to: context.eventLoop)
                .flatMap { context.pipeline.removeHandler(self) }
        }
    }
    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let input = unwrapInboundIn(data)
        
        switch state {
        case .ready:
            break
        case .applyingAction:
            // We're already applying a config action, so we just keep track of the data we've received in the meantime
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
