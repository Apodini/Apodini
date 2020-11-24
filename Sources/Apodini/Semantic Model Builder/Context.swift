//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 11/3/20.
//

import NIO


class Context {
    private let contextNode: ContextNode
    
    
    init(contextNode: ContextNode) {
        self.contextNode = contextNode
    }
    
    
    func get<C: ContextKey>(valueFor contextKey: C.Type = C.self) -> C.Value {
        contextNode.getContextValue(for: contextKey)
    }
    
    func createRequestHandler<C: Component, Req: Request, Res: Response>(withComponent component: C)
    -> (Req) -> EventLoopFuture<Res> {
        { (request: Req) in
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
                        var response = component.handle()
                        for responseTransformer in self.contextNode.getContextValue(for: ResponseContextKey.self) {
                            response = request.enterRequestContext(with: responseTransformer()) { responseTransformer in
                                responseTransformer.transform(response: response) as! C.Response
                            }
                        }

                        let vaporResponse = try! Res(body: response)
                        return request.eventLoop.makeSucceededFuture(vaporResponse)
                    }
                }
        }
    }
}
