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
import AsyncHTTPClient
import ApodiniUtils


class ProxyServer {
    struct Error: Swift.Error {
        let message: String
    }
    
    fileprivate let httpServer: HTTPServer
    fileprivate let logger = Logger(label: "DeploymentTargetLocalhost.ProxyServer")
    fileprivate let httpClient: AsyncHTTPClient.HTTPClient
    
    var eventLoopGroup: EventLoopGroup {
        httpServer.eventLoopGroup
    }
    
    
    init(openApiDocument: OpenAPI.Document, deployedSystem: AnyDeployedSystem, port: Int) throws {
        let httpServer = HTTPServer(eventLoopGroupProvider: .createNew, address: .interface("0.0.0.0", port: port), logger: logger)
        self.httpServer = httpServer
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
                    let handlerCommPatternRawValue = endpoint.operation.vendorExtensions["x-apodiniHandlerCommunicationalPattern"]?.value as? String,
                    let handlerCommPattern = Apodini.CommunicationalPattern(rawValue: handlerCommPatternRawValue)
                else {
                    throw Error(message: "Unable to fetch handler service type from OpenAPI document")
                }
                httpServer.registerRoute(
                    HTTPMethod(rawValue: endpoint.method.rawValue),
                    path.toHTTPPathComponentPath(),
                    responder: ProxyRequestResponder(
                        proxyServer: self,
                        targetNode: targetNode,
                        endpointCommPattern: handlerCommPattern
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
    func toHTTPPathComponentPath() -> [HTTPPathComponent] {
        self.components.map { component in
            if component.hasPrefix("{") && component.hasSuffix("}") {
                return .wildcardSingle
            } else {
                return .verbatim(component)
            }
        }
    }
}


private struct ProxyRequestResponder: HTTPResponder {
    let proxyServer: ProxyServer
    let targetNode: DeployedSystemNode
    let endpointCommPattern: Apodini.CommunicationalPattern
    
    private var httpClient: HTTPClient { proxyServer.httpClient }
    private var logger: Logger { proxyServer.logger }
    
    func respond(to incomingRequest: HTTPRequest) -> HTTPResponseConvertible {
        guard let targetNodeLocalhostData = targetNode.readUserInfo(as: LocalhostLaunchInfo.self) else {
            fatalError("Unable to read node userInfo")
        }
        logger.notice("[Proxy] Incoming HTTP Request \(incomingRequest.url)")
        let url = URI(
            scheme: incomingRequest.url.scheme,
            hostname: incomingRequest.url.hostname,
            port: targetNodeLocalhostData.port,
            path: incomingRequest.url.path,
            rawQuery: incomingRequest.url.rawQuery,
            fragment: incomingRequest.url.fragment
        )
        let forwardingRequest = try! HTTPClient.Request(
            url: URL(url),
            method: incomingRequest.method,
            headers: incomingRequest.headers,
            body: { () -> HTTPClient.Body in
                switch incomingRequest.bodyStorage {
                case .buffer(let buffer):
                    return .byteBuffer(buffer)
                case .stream(let stream):
                    return .stream(length: nil) { [unowned httpClient] streamWriter -> EventLoopFuture<Void> in
                        let promise = httpClient.eventLoopGroup.next().makePromise(of: Void.self)
                        stream.setObserver { stream, _ in
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
        let responseDelegate = AsyncHTTPClientForwardingResponseDelegate(
            on: httpClient.eventLoopGroup.next(),
            endpointCommPattern: endpointCommPattern
        )
        let reqEndFuture = proxyServer.httpClient.execute(request: forwardingRequest, delegate: responseDelegate).futureResult
        reqEndFuture.whenComplete { _ in
            print(responseDelegate)
        }
        return responseDelegate.httpResponseFuture
    }
}


private class AsyncHTTPClientForwardingResponseDelegate: HTTPClientResponseDelegate {
    typealias Response = Void
    
    private var response: HTTPResponse?
    private let endpointCommPattern: Apodini.CommunicationalPattern
    private let httpResponsePromise: EventLoopPromise<HTTPResponse>
    var httpResponseFuture: EventLoopFuture<HTTPResponse> { httpResponsePromise.futureResult }
    
    init(on eventLoop: EventLoop, endpointCommPattern: Apodini.CommunicationalPattern) {
        print(Self.self, #function)
        self.httpResponsePromise = eventLoop.makePromise(of: HTTPResponse.self)
        self.endpointCommPattern = endpointCommPattern
    }
    
    deinit {
        print(Self.self, #function)
    }
    
    func didReceiveHead(task: HTTPClient.Task<Response>, _ head: HTTPResponseHead) -> EventLoopFuture<Void> {
        print(Self.self, #function, head)
        guard response == nil else {
            return task.eventLoop.makeFailedFuture(ProxyServer.Error(message: "Already handling response"))
        }
        response = HTTPResponse(
            version: head.version,
            status: head.status,
            headers: head.headers,
            bodyStorage: {
                switch endpointCommPattern {
                case .requestResponse, .clientSideStream:
                    return .buffer()
                case .serviceSideStream, .bidirectionalStream:
                    return .stream()
                }
            }()
        )
        httpResponsePromise.succeed(response!)
        return task.eventLoop.makeSucceededVoidFuture()
    }
    
    func didReceiveBodyPart(task: HTTPClient.Task<Response>, _ buffer: ByteBuffer) -> EventLoopFuture<Void> {
        print(Self.self, buffer, buffer.getString(at: 0, length: buffer.readableBytes))
        guard let response = response else {
            return task.eventLoop.makeFailedFuture(ProxyServer.Error(message: "Already handling response"))
        }
        response.bodyStorage.write(buffer)
        return task.eventLoop.makeSucceededVoidFuture()
    }
    
    func didFinishRequest(task: HTTPClient.Task<Response>) throws -> Response {
        print(Self.self, #function)
        guard let response = response else {
            throw ProxyServer.Error(message: "Already handling response")
        }
        response.bodyStorage.stream?.close()
    }
}
