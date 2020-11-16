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
    
    // TODO: Schedule context key
    func createRequestHandler<C: Component>(withComponent component: C)
    -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        return { (request: Vapor.Request) in
            let guardEventLoopFutures = self.contextNode.getContextValue(for: GuardContextKey.self)
                .map { requestGuard in
                    request.enterRequestContext(with: requestGuard()) { requestGuard in
                        requestGuard.executeGuardCheck(on: request)
                    }
                }
            return EventLoopFuture<Void>
                .whenAllSucceed(guardEventLoopFutures, on: request.eventLoop)
                .flatMap { _ in
                    request.enterRequestContext(with: component) { component in
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
}
