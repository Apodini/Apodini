//
//  BidirectionalStreaming.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import Apodini
import ApodiniExtension
import ApodiniVaporSupport
import Vapor

@available(macOS 12.0, *)
extension Exporter {
    // MARK: Bidirectional Streaming Closure
    
    func buildBidirectionalStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore) -> (Vapor.Request) throws -> EventLoopFuture<Vapor.Response> {
        let strategy = multiInputDecodingStrategy(for: endpoint)
        
        let abortAnyError = AbortTransformer<H>()
        
        return { (request: Vapor.Request) in
            guard let requestCount = try configuration.decoder.decode(ArrayCount.self, from: request.bodyData).count else {
                throw ApodiniError(
                    type: .badInput,
                    reason: "Expected array at top level of body.",
                    description: "Input for client side steaming endpoints must be an array at top level.")
            }
            
            var delegate = Delegate(endpoint.handler, .required)
            
            return Array(0..<requestCount)
                .asAsyncSequence
                .map { index in
                    (request, (request, index))
                }
                .decode(using: strategy, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .validateParameterMutability()
                .cache()
                .subscribe(to: &delegate)
                .evaluate(on: &delegate)
                .transform(using: abortAnyError)
                .cancel(if: { response in
                    return response.connectionEffect == .close
                })
                .collect()
                .map { (responses: [Apodini.Response<H.Response.Content>]) in
                    let status: Status? = responses.last?.status
                    let information: Set<AnyInformation> = responses.last?.information ?? []
                    let content: [H.Response.Content] = responses.compactMap { response in
                        response.content
                    }
                    let body = try configuration.encoder.encode(content)
                    
                    return Vapor.Response(status: HTTPStatus(status ?? .ok),
                                          headers: HTTPHeaders(information),
                                          body: Vapor.Response.Body(data: body))
                }
                .firstFuture(on: request.eventLoop)
                .map { optionalResponse in
                    optionalResponse ?? Vapor.Response()
                }
        }
    }
}
