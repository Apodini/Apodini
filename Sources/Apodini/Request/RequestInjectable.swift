//
//  Request.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import Vapor


protocol RequestInjectable {
    func inject(using request: Vapor.Request, with decoder: SemanticModelBuilder?) throws
    func disconnect()
}


extension Vapor.Request {
    func enterRequestContext<E, R>(with element: E, using decoder: SemanticModelBuilder? = nil, executing method: (E) -> EventLoopFuture<R>)
    -> EventLoopFuture<R> {
        inject(in: element, using: decoder)
        
        return method(element)
            .map { response in
                self.disconnect(from: element)
                return response
            }
    }
    
    func enterRequestContext<E, R>(with element: E, using decoder: SemanticModelBuilder? = nil, executing method: (E) -> R) -> R {
        inject(in: element, using: decoder)
        let response = method(element)
        disconnect(from: element)
        return response
    }
    
    private func inject<E>(in element: E, using decoder: SemanticModelBuilder? = nil) {
        // Inject all properties that can be injected using RequestInjectable
        for child in Mirror(reflecting: element).children {
            if let requestInjectable = child.value as? RequestInjectable {
                do {
                    try requestInjectable.inject(using: self, with: decoder)
                } catch {
                    fatalError("Could not inject a value into a \(child.label ?? "UNKNOWN") property wrapper.")
                }
            }
        }
    }
    
    private func disconnect<E>(from element: E) {
        for child in Mirror(reflecting: element).children {
            if let requestInjectable = child.value as? RequestInjectable {
                requestInjectable.disconnect()
            }
        }
    }
}
