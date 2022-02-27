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
    func buildRequestResponseClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> {
        let strategy = singleInputDecodingStrategy(for: endpoint)
        let transformer = ErrorForwardingResultTransformer(
            wrapped: HTTPResponseTransformer<H>(configuration.encoder),
            forwarder: endpoint[ErrorForwarder.self]
        )
        let factory = endpoint[DelegateFactory<H, HTTPInterfaceExporter>.self]
        return { (request: HTTPRequest) in
            let delegate = factory.instance()
            return strategy
                .decodeRequest(from: request, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .cache()
                .forwardDecodingErrors(with: endpoint[ErrorForwarder.self])
                .evaluate(on: delegate)
                .transform(using: transformer)
                .map { response in
                    response.setContentLengthForCurrentBody()
                    return response
                }
        }
    }
    
    func buildRequestResponseClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> where H.Response.Content == Blob {
        let strategy = singleInputDecodingStrategy(for: endpoint)
        let transformer = ErrorForwardingResultTransformer(
            wrapped: HTTPBlobResponseTransformer(),
            forwarder: endpoint[ErrorForwarder.self]
        )
        let factory = endpoint[DelegateFactory<H, HTTPInterfaceExporter>.self]
        return { (request: HTTPRequest) in
            let delegate = factory.instance()
            return strategy
                .decodeRequest(from: request, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .cache()
                .forwardDecodingErrors(with: endpoint[ErrorForwarder.self])
                .evaluate(on: delegate)
                .transform(using: transformer)
                .map { response in
                    response.setContentLengthForCurrentBody()
                    return response
                }
        }
    }
}
