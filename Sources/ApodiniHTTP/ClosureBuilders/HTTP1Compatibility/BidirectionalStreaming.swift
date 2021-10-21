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


extension Exporter {
    func buildBidirectionalStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (LKHTTPRequest) throws -> EventLoopFuture<LKHTTPResponse> {
        let strategy = multiInputDecodingStrategy(for: endpoint)
        let abortAnyError = AbortTransformer<H>()
        let factory = endpoint[DelegateFactory<H, Exporter>.self]
        return { (request: LKHTTPRequest) in
            guard let requestCount = try configuration.decoder.decode(ArrayCount.self, from: request.bodyStorage.getFullBodyData() ?? .init()).count else {
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
                    return response.connectionEffect == .close
                })
                .collect()
                .map { (responses: [Apodini.Response<H.Response.Content>]) -> LKHTTPResponse in
                    let status: Status? = responses.last?.status
                    let information: InformationSet = responses.last?.information ?? []
                    let content: [H.Response.Content] = responses.compactMap { response in
                        response.content
                    }
                    let body = try configuration.encoder.encode(content)
                    
                    //return Vapor.Response(status: HTTPStatus(status ?? .ok),
                    //                      headers: HTTPHeaders(information),
                    //                      body: Vapor.Response.Body(data: body))
                    return LKHTTPResponse(
                        version: request.version, // TODO: since this seems to be evaluated in an async context, can we capture the request just like that?
                        status: HTTPResponseStatus(status ?? .ok),
                        headers: HTTPHeaders(information),
                        //body: .init(data: body)
                        bodyStorage: .buffer(initialValue: body) // TODO strem!!
                    )
                }
                .firstFuture(on: request.eventLoop)
                .map { optionalResponse in
                    precondition(optionalResponse != nil)
                    return optionalResponse ?? LKHTTPResponse(version: request.version, status: .ok, headers: [:]) // TODO what should this default request look like? old imoplementation somply returned an empty Vapor.Rwequest()
                }
        }
    }
}
