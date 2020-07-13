//
//  Visitor.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor


enum Scope {
    case nextComponent
    case environment
}


protocol Visitable {
    func visit(_ visitor: Visitor)
}


class Visitor {
    private(set) var currentNode: ContextNode = ContextNode()
    private(set) var app: Application
    
    
    init(_ app: Application) {
        self.app = app
    }
    
    
    func enter<C: ComponentCollection>(collection: C) {
        currentNode = currentNode.newContextNode()
    }
    
    func addContext<C: ContextKey>(_ contextKey: C.Type = C.self, value: C.Value, scope: Scope) {
        currentNode.addContext(contextKey, value: value, scope: scope)
    }
    
    func getContextValue<C: ContextKey>(for contextKey: C.Type = C.self) -> C.Value {
        currentNode.getContextValue(for: C.self)
    }
    
    func register<C: Component>(component: C) { }
    
    func createRequestHandler<C: Component>(withComponent component: C)
    -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        // We capture the currentContextNode and make a copy that will be used when execuring the request as
        // direcly capturing the currentNode would be influenced by the `resetContextNode()` call and using the
        // currentNode would always result in the last currentNode that was used when visiting the component tree.
        let currentContextNode = currentNode.copy()
        
        return { (request: Vapor.Request) in
            let guardEventLoopFutures = currentContextNode.getContextValue(for: GuardContextKey.self)
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
                        for responseTransformer in currentContextNode.getContextValue(for: ResponseContextKey.self) {
                            response = request.enterRequestContext(with: responseTransformer()) { responseTransformer in
                                responseTransformer.transform(response: response)
                            }
                        }
                        return response.encodeResponse(for: request)
                    }
                }
        }
    }
    
    func finishedRegisteringContext() {
        currentNode.resetContextNode()
    }
    
    func exit<C: ComponentCollection>(collection: C) {
        if let parentNode = currentNode.nodeLink {
            currentNode = parentNode
        }
    }
}
