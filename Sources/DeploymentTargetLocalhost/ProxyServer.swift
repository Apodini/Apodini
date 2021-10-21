//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import ApodiniNetworking
import ApodiniDeployBuildSupport
import DeploymentTargetLocalhostCommon
import Logging
import OpenAPIKit
import class Apodini.AnyHandlerIdentifier
import AsyncHTTPClient
import ApodiniUtils


class ProxyServer {
    struct Error: Swift.Error {
        let message: String
    }
    
    fileprivate let httpServer: LKNIOBasedHTTPServer
    fileprivate let logger = Logger(label: "DeploymentTargetLocalhost.ProxyServer")
    fileprivate var httpClient: AsyncHTTPClient.HTTPClient!
    
    var eventLoopGroup: EventLoopGroup {
        httpServer.eventLoopGroup
    }
    
    
    init(openApiDocument: OpenAPI.Document, deployedSystem: AnyDeployedSystem, port: Int) throws {
        self.httpServer = LKNIOBasedHTTPServer(eventLoopGroupProvider: .createNew, address: .hostname("0.0.0.0", port: port), logger: logger)
        self.httpClient = HTTPClient(eventLoopGroupProvider: .shared(httpServer.eventLoopGroup))
        
        logger.notice("Registering Proxy Server Routes")
        for (path, pathItem) in openApiDocument.paths {
            for endpoint in pathItem.endpoints {
                guard let handlerIdRawValue = endpoint.operation.vendorExtensions["x-apodiniHandlerId"]?.value as? String else {
                    throw Error(message: "Unable to read handlerId from OpenAPI document")
                }
                guard let targetNode = deployedSystem.nodeExportingEndpoint(withHandlerId: AnyHandlerIdentifier(handlerIdRawValue)) else {
                    throw Error(message: "Unable to find node for handler id '\(handlerIdRawValue)'")
                }
                guard
                    let handlerServiceTypeRawValue = endpoint.operation.vendorExtensions["x-apodiniHandlerServiceType"]?.value as? String,
                    let handlerServiceType = Apodini.ServiceType(rawValue: handlerServiceTypeRawValue)
                else {
                    throw Error(message: "Unable to fetch handler service type from OpenAPI document")
                }
                httpServer.registerRoute(
                    HTTPMethod(rawValue: endpoint.method.rawValue),
                    path.toHTTPPathComponentPath(),
                    responder: ProxyRequestResponder(
                        proxyServer: self,
                        targetNode: targetNode,
                        endpointServiceType: handlerServiceType
                    )
                )
            }
        }
    }
    
    
    deinit {
        do {
            try httpClient.syncShutdown()
        } catch {
            logger.error("Error shutting down httpClient: \(error)")
        }
        do {
            try httpServer.shutdown()
        } catch {
            logger.error("Error shutting down httpServer: \(error)")
        }
    }
    
    /// Start the proxy
    func start() throws {
        logger.notice("Starting Proxy HTTP server")
        try httpServer.start()
    }
    
    
    func stop() throws {
        logger.notice("Shutdown")
        try httpClient.syncShutdown()
        try httpServer.shutdown()
    }
}


extension OpenAPI.Path {
    func toHTTPPathComponentPath() -> [LKHTTPPathComponent] {
        self.components.map { component in
            if component.hasPrefix("{") && component.hasSuffix("}") {
                return .wildcardSingle
            } else {
                return .verbatim(component)
            }
        }
    }
}


private struct ProxyRequestResponder: LKHTTPRouteResponder {
    let proxyServer: ProxyServer
    let targetNode: DeployedSystemNode
    let endpointServiceType: Apodini.ServiceType
    
    private var httpClient: HTTPClient { proxyServer.httpClient }
    private var logger: Logger { proxyServer.logger }
    
    func respond(to incomingRequest: LKHTTPRequest) -> LKHTTPResponseConvertible {
        guard let targetNodeLocalhostData = targetNode.readUserInfo(as: LocalhostLaunchInfo.self) else {
            fatalError("Unable to read node userInfo")
        }
        logger.notice("[Proxy] Incoming HTTP Request \(incomingRequest.url)")
////        let url = Vapor.URI(
////            scheme: "http",
////            host: "127.0.0.1",
////            port: targetNodeLocalhostData.port,
////            path: request.url.path,
////            query: request.url.query,
////            fragment: request.url.fragment
////        )
//        let url = LKURL(
//            scheme: .http,
//            hostname: "127.0.0.1",
//            port: targetNodeLocalhostData.port,
//            path: request.url.path,
//            rawQuery: request.url.rawQuery,
//            fragment: request.url.fragment
//        )
//        proxyServer.logger.notice("forwarding request to '\(url)'")
////        let clientResponseFuture = request.client.send(request.method, headers: request.headers, to: url) { (clientReq: inout ClientRequest) in
////            clientReq.body = request.body.data
////        }
////        return clientResponseFuture.flatMap { clientResponse in
////            // Note: For some reason, Vapor will duplicate some header fields when sending this response back to the client.
////            // The ones i noticed were `date` and `connection`, but that's probably not the full list.
////            let ignoredHeaderFields: [HTTPHeaders.Name] = [.date, .connection]
////            let response = Response(
////                status: clientResponse.status,
////                //version, // `ClientResponse` doesn't have a version, we could use the default (what we're doing) or return the initial request's version
////                headers: HTTPHeaders(clientResponse.headers.filter { !ignoredHeaderFields.contains(HTTPHeaders.Name($0.name)) }),
////                body: clientResponse.body.map { Response.Body(buffer: $0) } ?? .empty
////            )
////            return proxyServer.app.eventLoopGroup.next().makeSucceededFuture(response)
////        }
////        let clientResponseFuture = proxyServer.httpClient.post(url: url, body: <#T##Body?#>, deadline: <#T##NIODeadline?#>) request.client.send(request.method, headers: request.headers, to: url) { (clientReq: inout ClientRequest) in
////            clientReq.body = request.body.data
////        }
//
//        //let xxxx = proxyServer.httpClient.post(url: url.stringValue, body: .data(request.bodyData), logger: proxyServer.logger)
//        return proxyServer.httpClient.execute(request: try! HTTPClient.Request(
//            url: url.stringValue,
//            method: .POST,
//            headers: request.headers,
//            //body: .data(request.bodyStorage.getFullBodyData())
//            body: { () -> AsyncHTTPClient.HTTPClient.Body in
//                switch request.bodyStorage {
//                case .buffer(let buffer):
//                    return .byteBuffer(buffer)
//                case .stream(let stream):
//                    let streamEndPromise = request.eventLoop.makePromise(of: Void.self)
//                    let numClosureInvocations = Box(0)
//                    return .stream(length: nil) { (streamWriter: HTTPClient.Body.StreamWriter) -> EventLoopFuture<Void> in
//                        print("DID CALL THE THING!!!") // TODO make sure this only gets called once!
//                        numClosureInvocations.value += 1
//                        precondition(numClosureInvocations.value == 1)
//                        stream.setObserver { stream, event in
//                            if let newData = stream.readNewData() {
//                                try! streamWriter.write(IOData.byteBuffer(newData)).wait() // TODO is this (the wait) important?
//                            }
//                            if stream.isClosed {
//                                streamEndPromise.succeed(())
//                            }
//                        }
////                        stream.newDataWrittenHandler = { [unowned stream] in
////                            // TODO this wont work bc it'd run into the already-taken lock and wait on that :/
////                        }
////                        stream.closeHandler = { [unowned stream] in
////                            precondition(stream.isClosed)
////                            streamEndPromise.succeed(())
////                        }
//                        return streamEndPromise.futureResult
//                    }
//                }
//            }()
//        )).map { (clientResponse: AsyncHTTPClient.HTTPClient.Response) -> LKHTTPResponse in
//            // Note: For some reason, Vapor will duplicate some header fields when sending this response back to the client.
//            // The ones i noticed were `date` and `connection`, but that's probably not the full list.
//            //let ignoredHeaderFields: [HTTPHeaders.HeaderName] = [.date, .connection]
//            let ignoredHeaderFieldNames: [String] = []// TODO check whether there are duplicate headers using the new setup!
//            //let ignored2: [String] = [HTTPHeaders.AnyHeaderName.date, .connection].map(\.rawValue)
////            let responsee = Response(
////                status: clientResponse.status,
////                //version, // `ClientResponse` doesn't have a version, we could use the default (what we're doing) or return the initial request's version
////                headers: HTTPHeaders(clientResponse.headers.filter { !ignoredHeaderFields.contains(HTTPHeaders.Name($0.name)) }),
////                body: clientResponse.body.map { Response.Body(buffer: $0) } ?? .empty
////            )
//            // TODO properly handle the hop-by-hop headers!
//            // TODO what about streaming client responses???? Does the AsyncHTTPClient even support that in the first place? Or does it just wait and then return everything at once?
//            let response = LKHTTPResponse(
//                version: request.version,
//                status: clientResponse.status,
//                headers: HTTPHeaders(clientResponse.headers.filter { !ignoredHeaderFieldNames.contains($0.name) }),
//                //body: clientResponse.body ?? .init()
//                bodyStorage: .buffer(clientResponse.body ?? .init())
//            )
////            precondition(proxyServer.httpServer.eventLoopGroup.next() == request.eventLoop)
//            //return proxyServer.app.eventLoopGroup.next().makeSucceededFuture(response)
//            return response
//        }
        
        let url = LKURL(
            scheme: incomingRequest.url.scheme,
            hostname: incomingRequest.url.hostname,
            port: targetNodeLocalhostData.port,
            path: incomingRequest.url.path,
            rawQuery: incomingRequest.url.rawQuery,
            fragment: incomingRequest.url.fragment
        )
        
        
        let forwardingRequest = try! HTTPClient.Request(
            url: url.toNSURL(),
            method: incomingRequest.method,
            headers: incomingRequest.headers,
            body: { () -> HTTPClient.Body in
                switch incomingRequest.bodyStorage {
                case .buffer(let buffer):
                    return .byteBuffer(buffer)
                case .stream(let stream):
                    return .stream(length: nil) { [unowned httpClient] streamWriter -> EventLoopFuture<Void> in
                        let promise = httpClient.eventLoopGroup.next().makePromise(of: Void.self)
                        stream.setObserver { stream, event in
                            if let buffer = stream.readNewData() {
                                try! streamWriter.write(.byteBuffer(buffer)).wait()
                            }
                            if stream.isClosed {
                                promise.succeed(())
                            }
                        }
                        return promise.futureResult
                    }
                }
            }()
        )
        let responseDelegate = AsyncHTTPClientForwardingResonseDelegate(on: httpClient.eventLoopGroup.next(), endpointServiceType: endpointServiceType)
        _ = proxyServer.httpClient.execute(request: forwardingRequest, delegate: responseDelegate)
        return responseDelegate.httpResponseFuture
    }
}



private class AsyncHTTPClientForwardingResonseDelegate: HTTPClientResponseDelegate {
    typealias Response = Void
    
    private var response: LKHTTPResponse?
    private let endpointServiceType: Apodini.ServiceType
    private let httpResponsePromise: EventLoopPromise<LKHTTPResponse>
    var httpResponseFuture: EventLoopFuture<LKHTTPResponse> { httpResponsePromise.futureResult }
    
    init(on eventLoop: EventLoop, endpointServiceType: Apodini.ServiceType) {
        self.httpResponsePromise = eventLoop.makePromise(of: LKHTTPResponse.self)
        self.endpointServiceType = endpointServiceType
    }
    
    func didReceiveHead(task: HTTPClient.Task<Response>, _ head: HTTPResponseHead) -> EventLoopFuture<Void> {
        guard response == nil else {
            return task.eventLoop.makeFailedFuture(ProxyServer.Error(message: "Already handling response"))
        }
        response = LKHTTPResponse(
            version: head.version,
            status: head.status,
            headers: head.headers,
            bodyStorage: {
                switch endpointServiceType {
                case .unary, .clientStreaming:
                    return .buffer()
                case .serviceStreaming, .bidirectional:
                    return .stream()
                }
            }()
        )
        httpResponsePromise.succeed(response!)
        return task.eventLoop.makeSucceededVoidFuture()
    }
    
    func didReceiveBodyPart(task: HTTPClient.Task<Response>, _ buffer: ByteBuffer) -> EventLoopFuture<Void> {
        guard let response = response else {
            return task.eventLoop.makeFailedFuture(ProxyServer.Error(message: "Already handling response"))
        }
        response.bodyStorage.write(buffer)
        return task.eventLoop.makeSucceededVoidFuture()
    }
    
    func didFinishRequest(task: HTTPClient.Task<Response>) throws -> Response {
        guard let response = response else {
            throw ProxyServer.Error(message: "Already handling response")
        }
        response.bodyStorage.stream?.close()
    }
}
