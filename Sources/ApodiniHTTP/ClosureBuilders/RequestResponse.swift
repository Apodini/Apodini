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


extension Exporter {
    // TODO there's a lot of redundancy here!!!
    func buildRequestResponseClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (LKHTTPRequest) throws -> EventLoopFuture<LKHTTPResponse> {
        let strategy = singleInputDecodingStrategy(for: endpoint)
        let transformer = LKHTTPResponseTransformer<H>(configuration.encoder)
        let factory = endpoint[DelegateFactory<H, Exporter>.self]
        return { (request: LKHTTPRequest) in
            let delegate = factory.instance()
            return strategy
                .decodeRequest(from: request, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .cache()
                .evaluate(on: delegate)
                .transform(using: transformer)
        }
    }
    
    func buildRequestResponseClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (LKHTTPRequest) throws -> EventLoopFuture<LKHTTPResponse> where H.Response.Content == Blob {
        let strategy = singleInputDecodingStrategy(for: endpoint)
        let transformer = LKHTTPBlobResponseTransformer()
        let factory = endpoint[DelegateFactory<H, Exporter>.self]
        return { (request: LKHTTPRequest) in
            let delegate = factory.instance()
            return strategy
                .decodeRequest(from: request, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .cache()
                .evaluate(on: delegate)
                .transform(using: transformer)
        }
    }
}
