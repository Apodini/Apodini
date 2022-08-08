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


extension HTTPInterfaceExporter {
    func buildClientSideStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> {
        let strategy = multiInputDecodingStrategy(for: endpoint)
        let abortAnyError = ErrorForwardingResultTransformer(
            wrapped: AbortTransformer<H>(),
            forwarder: endpoint[ErrorForwarder.self]
        )
        let factory = endpoint[DelegateFactory<H, HTTPInterfaceExporter>.self]
        let delegate = factory.instance()
        
        return { [unowned self] (request: HTTPRequest) in
            let decodingSequence: AnyAsyncSequence<DefaultValueStore.DefaultInsertingRequest>
            if request.version.major == 2 {
                decodingSequence = try self.lengthPrefixDecodingSequence(request, defaultValues, endpoint)
            } else {
                decodingSequence = try self.arrayDecodingSequence(request, defaultValues, endpoint)
            }
            
            let decodeAndHandle: AnyAsyncSequence<Apodini.Response<H.Response.Content>> = decodingSequence
                .validateParameterMutability()
                .cache()
                .forwardDecodingErrors(with: endpoint[ErrorForwarder.self])
                .subscribe(to: delegate)
                .evaluate(on: delegate)
                .transform(using: abortAnyError)
                .cancelIf { $0.connectionEffect == .close }
                .compactMap { (response: Apodini.Response<H.Response.Content>) in
                    // Don't do anything if this is an intermediary response
                    if response.connectionEffect == .open && response.content == nil {
                        return nil
                    } else {
                        return response
                    }
                }
                .firstAndThenError(StreamingError.moreThanOneResponse)
                .typeErased
            
            if request.version.major == 2 {
                return decodeAndHandle.encodeForHTTP2Streaming(request, self.logger, self.configuration.encoder, endpoint)
            } else {
                return decodeAndHandle.encodeAsHTTPResponse(request, self.configuration.encoder)
            }
        }
    }
}
