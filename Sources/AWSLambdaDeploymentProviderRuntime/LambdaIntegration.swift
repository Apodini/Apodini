//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
//
// This code is based on the vapor-aws-lambda-runtime project: https://github.com/vapor-community/vapor-aws-lambda-runtime
//
// SPDX-FileCopyrightText: 2020-2022 the vapor-aws-lambda authors
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Apodini
import ApodiniNetworking
import AWSLambdaRuntimeCore
import AWSLambdaEvents
import Dispatch


private enum LambdaHandlerError: Swift.Error {
    case inivalidHTTPVersion(String)
    case invalidPath(path: String, query: String)
    case unableToDecodeBody
}


struct APIGatewayV2Handler: EventLoopLambdaHandler {
    typealias In = APIGateway.V2.Request // swiftlint:disable:this type_name
    typealias Out = APIGateway.V2.Response
    
    let httpServer: HTTPServer
    
    func handle(context: Lambda.Context, event: APIGateway.V2.Request) -> EventLoopFuture<APIGateway.V2.Response> {
        guard let httpVersion = HTTPVersion(string: event.context.http.protocol) else {
            return context.eventLoop.makeFailedFuture(LambdaHandlerError.inivalidHTTPVersion(event.context.http.protocol))
        }
        guard let uri = URI(string: "\(event.context.http.path)?\(event.rawQueryString)") else {
            return context.eventLoop.makeFailedFuture(LambdaHandlerError.invalidPath(path: event.context.http.path, query: event.rawQueryString))
        }
        let reqBody: ByteBuffer
        switch (event.body, event.isBase64Encoded) {
        case (let .some(body), false):
            reqBody = context.allocator.buffer(string: body)
        case (let .some(body), true):
            guard let data = Data(base64Encoded: body) else {
                return context.eventLoop.makeFailedFuture(LambdaHandlerError.unableToDecodeBody)
            }
            reqBody = context.allocator.buffer(data: data)
        case (.none, _):
            reqBody = ByteBuffer()
        }
        let request = HTTPRequest(
            remoteAddress: nil,
            version: httpVersion,
            method: .init(rawValue: event.context.http.method.rawValue),
            url: uri,
            headers: .init(event.headers.map { ($0.key, $0.value) }),
            bodyStorage: .buffer(reqBody),
            eventLoop: context.eventLoop
        )
        return httpServer
            .respond(to: request)
            .makeHTTPResponse(for: request)
            .hop(to: context.eventLoop)
            .flatMap { (response: HTTPResponse) -> EventLoopFuture<APIGateway.V2.Response> in
                let bodyFuture: EventLoopFuture<ByteBuffer>
                switch response.bodyStorage {
                case .buffer(let buffer):
                    bodyFuture = context.eventLoop.makeSucceededFuture(buffer)
                case .stream(let stream):
                    bodyFuture = stream.collect(on: context.eventLoop)
                }
                return bodyFuture.map { buffer -> APIGateway.V2.Response in
                    APIGateway.V2.Response(
                        statusCode: .init(code: response.status.code),
                        headers: response.headers.mapIntoDict { ($0.name, $0.value) },
                        body: Data(buffer: buffer).base64EncodedString(),
                        isBase64Encoded: true
                    )
                }
            }
    }
    
    func decode(buffer: ByteBuffer) throws -> APIGateway.V2.Request {
        try JSONDecoder().decode(APIGateway.V2.Request.self, from: buffer)
    }
    
    func encode(allocator: ByteBufferAllocator, value: APIGateway.V2.Response) throws -> ByteBuffer? {
        try JSONEncoder().encodeAsByteBuffer(value, allocator: allocator)
    }
}


class LambdaServer: Apodini.LifecycleHandler {
    private let application: Application
    private let eventLoop: any EventLoop
    private let lambdaLifecycle: Lambda.Lifecycle
    
    init(application: Application) {
        let eventLoop = application.eventLoopGroup.next()
        self.application = application
        self.eventLoop = eventLoop
        self.lambdaLifecycle = Lambda.Lifecycle(
            eventLoop: eventLoop,
            logger: application.logger,
            factory: { ctx in
                ctx.eventLoop.makeSucceededFuture(APIGatewayV2Handler(httpServer: application.httpServer))
            }
        )
    }
    
    func didBoot(_ application: Application) throws {
        eventLoop.execute {
            _ = self.lambdaLifecycle.start()
        }
        self.lambdaLifecycle.shutdownFuture.whenComplete { _ in
            DispatchQueue(label: "shutdown").async {
                self.application.shutdown()
            }
        }
    }
    
    func shutdown(_ application: Application) throws {}
}
