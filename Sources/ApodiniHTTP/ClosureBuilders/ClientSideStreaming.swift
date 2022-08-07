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
        _buildClientSideStreamingClosure(
            for: endpoint,
            using: defaultValues,
            resultTransformer: HTTPResponseTransformer<H>(configuration.encoder)
        )
    }
    
    func buildClientSideStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> where H.Response.Content == Blob {
        _buildClientSideStreamingClosure(
            for: endpoint,
            using: defaultValues,
            resultTransformer: HTTPBlobResponseTransformer()
        )
    }
    
    private func _buildClientSideStreamingClosure<H: Handler, RT: ResultTransformer>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore,
        resultTransformer: RT
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> where RT.Input == Apodini.Response<H.Response.Content>, RT.Output == HTTPResponse {
        let strategy = multiInputDecodingStrategy(for: endpoint)
        let abortAnyError = ErrorForwardingResultTransformer(
            wrapped: AbortTransformer<H>(),
            forwarder: endpoint[ErrorForwarder.self]
        )
        let transformer = ErrorForwardingResultTransformer(
            wrapped: resultTransformer,
            forwarder: endpoint[ErrorForwarder.self]
        )
        let factory = endpoint[DelegateFactory<H, HTTPInterfaceExporter>.self]
        return { [unowned self] (request: HTTPRequest) in
            
        }
    }
    
    private func http1RequestSequence() {
        
    }
    
    private func http2RequestSequence() {
        
    }
    
    private func buildHTTP1Sequence() {
        [unowned self] (request: HTTPRequest) in
           guard let requestCount = try? configuration.decoder.decode(
               ArrayCount.self,
               from: request.bodyStorage.getFullBodyData() ?? .init()
           ).count else {
               throw ApodiniError(
                   type: .badInput,
                   reason: "Expected array at top level of body.",
                   description: "Input for client side steaming endpoints must be an array at top level."
               )
           }
           let delegate = factory.instance()
           return Array(0..<requestCount)
               .map { index in
                   (request, (request, index))
               }
               .asAsyncSequence
               .decode(using: strategy, with: request.eventLoop)
               .insertDefaults(with: defaultValues)
               .validateParameterMutability()
               .cache()
               .forwardDecodingErrors(with: endpoint[ErrorForwarder.self])
               .subscribe(to: delegate)
               .evaluate(on: delegate)
               .transform(using: abortAnyError)
               .cancelIf { $0.connectionEffect == .close }
               .compactMap { (response: Apodini.Response<H.Response.Content>) in
                   if response.connectionEffect == .open && response.content == nil {
                       return nil
                   } else {
                       return response
                   }
               }
               .map { (response: Apodini.Response<H.Response.Content>) -> HTTPResponse in
                   try! transformer.transform(input: response)
               }
               .firstFuture(on: request.eventLoop)
               .map { response in
                   precondition(response != nil)
                   response?.setContentLengthForCurrentBody()
                   return response ?? HTTPResponse(version: request.version, status: .ok, headers: [:])
               }
    }
    
    private func buildHTTP2Sequence() {
        [unowned self] (request: HTTPRequest) in
            guard let requestCount = try? configuration.decoder.decode(
                ArrayCount.self,
                from: request.bodyStorage.getFullBodyData() ?? .init()
            ).count else {
                throw ApodiniError(
                    type: .badInput,
                    reason: "Expected array at top level of body.",
                    description: "Input for client side steaming endpoints must be an array at top level."
                )
            }
            let delegate = factory.instance()
            return Array(0..<requestCount)
                .map { index in
                    (request, (request, index))
                }
                .asAsyncSequence
                .decode(using: strategy, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .validateParameterMutability()
                .cache()
                .forwardDecodingErrors(with: endpoint[ErrorForwarder.self])
                .subscribe(to: delegate)
                .evaluate(on: delegate)
                .transform(using: abortAnyError)
                .cancelIf { $0.connectionEffect == .close }
                .compactMap { (response: Apodini.Response<H.Response.Content>) in
                    if response.connectionEffect == .open && response.content == nil {
                        return nil
                    } else {
                        return response
                    }
                }
                .map { (response: Apodini.Response<H.Response.Content>) -> HTTPResponse in
                    try! transformer.transform(input: response)
                }
                .firstFuture(on: request.eventLoop)
                .map { response in
                    precondition(response != nil)
                    response?.setContentLengthForCurrentBody()
                    return response ?? HTTPResponse(version: request.version, status: .ok, headers: [:])
                }
    }
}
