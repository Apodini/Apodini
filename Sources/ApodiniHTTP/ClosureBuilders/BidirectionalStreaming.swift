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
import ApodiniHTTPProtocol
import ApodiniNetworking
import Logging


extension HTTPInterfaceExporter {
    private func buildBidirectionalStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> {
        let abortAnyError = ErrorForwardingResultTransformer(
            wrapped: AbortTransformer<H>(),
            forwarder: endpoint[ErrorForwarder.self]
        )
        let factory = endpoint[DelegateFactory<H, HTTPInterfaceExporter>.self]
        return { [unowned self] (request: HTTPRequest) in
            let requestSequence: AnyAsyncSequence<DefaultValueStore.DefaultInsertingRequest>
            
            do {
                if request.version.major == 2 {
                    requestSequence = try self.http1RequestSequence(request, defaultValues, endpoint)
                } else {
                    requestSequence = try self.http2RequestSequence(request, defaultValues, endpoint)
                }
            } catch {
                endpoint[ErrorForwarder.self].forward(error)
                throw error
            }
            
            let delegate = factory.instance()
            
            let requestProcessor = requestSequence
                .validateParameterMutability()
                .cache()
                .forwardDecodingErrors(with: endpoint[ErrorForwarder.self])
                .subscribe(to: delegate)
                .evaluate(on: delegate)
                .transform(using: abortAnyError)
                .cancelIf { $0.connectionEffect == .close }
                
            if request.version.major == 2 {
                return requestProcessor.http2ResponseSequence(request, self.logger, self.configuration.encoder, endpoint)
            } else {
                return requestProcessor.http1ResponseSequence(request, self.configuration.encoder, endpoint)
            }
        }
    }
}
