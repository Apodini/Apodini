//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import ApodiniExtension
import ApodiniNetworking
import Logging


extension HTTPInterfaceExporter {
    func buildServiceSideStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> {
        let abortAnyError = ErrorForwardingResultTransformer(
            wrapped: AbortTransformer<H>(),
            forwarder: endpoint[ErrorForwarder.self]
        )
        let factory = endpoint[DelegateFactory<H, HTTPInterfaceExporter>.self]
        
        return { [unowned self] (request: HTTPRequest) throws -> EventLoopFuture<HTTPResponse> in
            let delegate = factory.instance()
            
            let decodeSequence: AnyAsyncSequence<DefaultValueStore.DefaultInsertingRequest>
            if request.version.major == 2 {
                decodeSequence = try singleLengthPrefixedDecodingSequence(request, defaultValues, endpoint)
            } else {
                decodeSequence = singleDecodingSequence(request, defaultValues, endpoint)
            }
            
            let decodeAndHandle = decodeSequence
                .cache()
                .forwardDecodingErrors(with: endpoint[ErrorForwarder.self])
                .subscribe(to: delegate)
                .evaluate(on: delegate)
                .transform(using: abortAnyError)
                .cancelIf { $0.connectionEffect == .close }
                .typeErased
            
            if request.version.major == 2 {
                return decodeAndHandle.encodeForHTTP2Streaming(request, self.logger, configuration.encoder, endpoint)
            } else {
                return decodeAndHandle.encodeAsArray(request, configuration.encoder, endpoint)
            }
        }
    }
}
