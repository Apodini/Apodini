//
//  ClientSideStreaming.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import Apodini
import ApodiniExtension
import ApodiniVaporSupport
import Vapor

extension Exporter {
    // MARK: Client Streaming Closure
    
    func buildClientSideStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore) -> (Vapor.Request) throws -> EventLoopFuture<Vapor.Response> {
        let strategy = multiInputDecodingStrategy(for: endpoint)
        
        let abortAnyError = AbortTransformer<H>()
        
        let transformer = VaporResponseTransformer<H>(configuration.encoder)
            
        let factory = endpoint[DelegateFactory<H>.self]
        
        return { (request: Vapor.Request) in
            guard let requestCount = try configuration.decoder.decode(ArrayCount.self, from: request.bodyData).count else {
                throw ApodiniError(
                    type: .badInput,
                    reason: "Expected array at top level of body.",
                    description: "Input for client side steaming endpoints must be an array at top level.")
            }
            
            let delegate = factory.instance()
            
            return Array(0..<requestCount)
                .asAsyncSequence
                .map { index in
                    (request, (request, index))
                }
                .decode(using: strategy, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .validateParameterMutability()
                .cache()
                .subscribe(to: delegate)
                .evaluate(on: delegate)
                .transform(using: abortAnyError)
                .cancel(if: { response in
                    response.connectionEffect == .close
                })
                .compactMap { (response: Apodini.Response<H.Response.Content>) in
                    if response.connectionEffect == .open && response.content == nil {
                        return nil
                    } else {
                        return response
                    }
                }
                .map { (response: Apodini.Response<H.Response.Content>) -> Vapor.Response in
                    return try transformer.transform(input: response)
                }
                .firstFuture(on: request.eventLoop)
                .map { optionalResponse in
                    optionalResponse ?? Vapor.Response()
                }
        }
    }
}
