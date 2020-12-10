//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 11/3/20.
//

import Vapor


class Context {
    private let contextNode: ContextNode
    
    
    init(contextNode: ContextNode) {
        self.contextNode = contextNode
    }
    
    
    func get<C: ContextKey>(valueFor contextKey: C.Type = C.self) -> C.Value {
        contextNode.getContextValue(for: contextKey)
    }
    
    func createRequestHandler<C: Component>(withComponent component: C, using decoder: SemanticModelBuilder)
    -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        { (request: Vapor.Request) in
            let guardEventLoopFutures = self.contextNode.getContextValue(for: GuardContextKey.self)
                .map { requestGuard in
                    request.enterRequestContext(with: requestGuard(), using: decoder) { requestGuard in
                        requestGuard.executeGuardCheck(on: request)
                    }
                }
            return EventLoopFuture<Void>
                .whenAllSucceed(guardEventLoopFutures, on: request.eventLoop)
                .flatMap { _ in
                    request.enterRequestContext(with: component, using: decoder) { component in
                        var response: ResponseEncodable = component.handle()
                        for responseTransformer in self.contextNode.getContextValue(for: ResponseContextKey.self) {
                            response = request.enterRequestContext(with: responseTransformer()) { responseTransformer in
                                responseTransformer.transform(response: response)
                            }
                        }
                        return response.encodeResponse(for: request)
                    }
                }
        }
    }

    func createClientStreamRequestHandler<C: Component>(withComponent component: C, using decoder: SemanticModelBuilder)
    -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        { (request: Vapor.Request) in
            let resultPromise = request.eventLoop.makePromise(of: Vapor.Response.self)
            request.body.drain { (bodyStream: BodyStreamResult) in
                switch bodyStream {
                case .buffer(_):
                    let con = Connection(state: .open)
                    _ = self.createRequestHandler(withComponent: component.withEnviromment(con, for: \.connection),
                                                  using: decoder)(request)
                case let .error(error):
                    return request.eventLoop.makeFailedFuture(error)
                case .end:
                    let con = Connection(state: .end)
                    let response = self.createRequestHandler(withComponent: component.withEnviromment(con, for: \.connection),
                                                             using: decoder)(request)
                    let result = response.encodeResponse(for: request)
                    resultPromise.completeWith(result)
                }
                return request.eventLoop.makeSucceededFuture(())
            }
            return resultPromise.futureResult
        }
    }
}
