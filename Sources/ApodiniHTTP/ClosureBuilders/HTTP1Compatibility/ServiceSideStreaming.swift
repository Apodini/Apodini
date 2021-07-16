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
    // MARK: Service Streaming Closure
    
    func buildServiceSideStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore) -> (Vapor.Request) throws -> EventLoopFuture<Vapor.Response> {
        let strategy = singleInputDecodingStrategy(for: endpoint)
        
        let abortAnyError = AbortTransformer<H>()
        
        return { (request: Vapor.Request) in
            var delegate = Delegate(endpoint.handler, .required)
            
            return Just(request)
                .decode(using: strategy, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .validateParameterMutability()
                .cache()
                .subscribe(to: &delegate)
                .evaluate(on: &delegate)
                .transform(using: abortAnyError)
                .cancel(if: { response in
                    response.connectionEffect == .close
                })
                .collect()
                .tryMap { (responses: [Apodini.Response<H.Response.Content>]) in
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
