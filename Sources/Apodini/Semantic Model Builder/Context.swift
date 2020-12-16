//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 11/3/20.
//

import Vapor

enum ContextError: Error {
    case unsupportedAction(_ message: String)
}

class Context {
    private let contextNode: ContextNode
    
    
    init(contextNode: ContextNode) {
        self.contextNode = contextNode
    }
    
    
    func get<C: ContextKey>(valueFor contextKey: C.Type = C.self) -> C.Value {
        contextNode.getContextValue(for: contextKey)
    }

    private func processGuards(_ request: Vapor.Request, using decoder: SemanticModelBuilder) -> [EventLoopFuture<Void>] {
        return self.contextNode.getContextValue(for: GuardContextKey.self)
            .map { requestGuard in
                request.enterRequestContext(with: requestGuard(), using: decoder) { requestGuard in
                    requestGuard.executeGuardCheck(on: request)
                }
            }
    }

    @available(*, deprecated, message: "To be replaced by the `requestHandlerBuilder` in the Endpoint model. See SharedSemanticModelBuilder")
    func createRequestHandler<C: Component>(withComponent component: C, using decoder: SemanticModelBuilder)
    -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        { (request: Vapor.Request) in
            let guardEventLoopFutures = self.processGuards(request, using: decoder)
            return EventLoopFuture<Void>
                .whenAllSucceed(guardEventLoopFutures, on: request.eventLoop)
                .flatMap { _ in
                    request.enterRequestContext(with: component, using: decoder) { component in
                        let response: Action<C.Response> = component.handle()
                        switch response {
                        case let .final(element):
                            var encodable: ResponseEncodable = element
                            for responseTransformer in self.contextNode.getContextValue(for: ResponseContextKey.self) {
                                encodable = request.enterRequestContext(with: responseTransformer()) { responseTransformer in
                                    responseTransformer.transform(response: encodable)
                                }
                            }

                            return encodable.encodeResponse(for: request)
                        default: // .send and .nothing are not supported by unary endpoints
                            let err = ContextError.unsupportedAction("Actions .send and .nothing are not supported by unary endpoints." +
                                "Use a streaming endpoint instead.")
                            return request.eventLoop.makeFailedFuture(err)
                        }
                    }
                }
        }
    }

    /// Used by the GRPCSemanticModelBuilder to export client-side streaming endpoints.
    func createClientStreamRequestHandler<C: Component>(withComponent component: C, using decoder: SemanticModelBuilder)
    -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        { (request: Vapor.Request) in
            let resultPromise = request.eventLoop.makePromise(of: Vapor.Response.self)
            request.body.drain { (bodyStream: BodyStreamResult) in
                let con: Connection
                switch bodyStream {
                case let .buffer(byteBuffer):
                    con = Connection(state: .open)
                    #if DEBUG
                    if let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) {
                        print("\([UInt8](data))")
                    }
                    #endif
                    // TODO check data for completenes (using length-info at beginning)
                    // & collect multiple frames if necessary
                    // cite: https://grpc.io/blog/grpc-on-http2/
                    // "RPCs are in practice plain HTTP/2 streams.
                    // Messages are associated with RPCs and get sent as HTTP/2 data frames.
                    // To be more specific, messages are layered on top of data frames.
                    // A data frame may have many gRPC messages,
                    // or if a gRPC message is quite large it might span multiple data frames."
                case .end:
                    con = Connection(state: .end)
                case let .error(error):
                    return request.eventLoop.makeFailedFuture(error)
                }

                let guardEventLoopFutures = self.processGuards(request, using: decoder)
                return EventLoopFuture<Void>
                    .whenAllSucceed(guardEventLoopFutures, on: request.eventLoop)
                    .flatMap { _ in
                        request.enterRequestContext(with: component, using: decoder) { component in
                            let response: Action<C.Response> = component
                                .withEnvironment(con, for: \.connection)
                                .handle()
                            switch response {
                            case let .send(element),
                                 let .final(element):
                                var encodable: ResponseEncodable = element
                                for responseTransformer in self.contextNode.getContextValue(for: ResponseContextKey.self) {
                                    encodable = request.enterRequestContext(with: responseTransformer(), using: decoder) { responseTransformer in
                                        responseTransformer.transform(response: encodable)
                                    }
                                }
                                let response = encodable.encodeResponse(for: request)
                                resultPromise.completeWith(response)
                            default: // .nothing
                                // we do nothing 😆
                                break
                            }
                            return request.eventLoop.makeSucceededFuture(())
                        }
                    }
            }
            return resultPromise.futureResult
        }
    }
}
