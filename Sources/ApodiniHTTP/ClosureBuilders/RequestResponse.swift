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
import ApodiniVaporSupport
import OpenCombine
import Vapor

extension Exporter {
    // MARK: Request Response Closure
    
    func buildRequestResponseClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore) -> (Vapor.Request) throws -> EventLoopFuture<Vapor.Response> {
        let strategy = singleInputDecodingStrategy(for: endpoint)
        
        let transformer = VaporResponseTransformer<H>(configuration.encoder)
        
        return { (request: Vapor.Request) in
            var delegate = Delegate(endpoint.handler, .required)
            
            return strategy
                .decodeRequest(from: request, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .cache()
                .evaluate(on: &delegate)
                .transform(using: transformer)
        }
    }
    
    // MARK: Blob Request Response Closure
    
    func buildBlobRequestResponseClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore) -> (Vapor.Request) throws -> EventLoopFuture<Vapor.Response> where H.Response.Content == Blob {
        let strategy = singleInputDecodingStrategy(for: endpoint)
        
        let transformer = VaporBlobResponseTransformer()
        
        return { (request: Vapor.Request) in
            var delegate = Delegate(endpoint.handler, .required)
            
            return strategy
                .decodeRequest(from: request, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .cache()
                .evaluate(on: &delegate)
                .transform(using: transformer)
        }
    }
}
