//
//  Request.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import Vapor


protocol RequestInjectable {
    func inject(using request: Vapor.Request) throws
    func disconnect()
}

// TODO Is there ANY better place to place this than on global?
func extractRequestInjectables(from subject: Any) -> [String : RequestInjectable] {
    Mirror(reflecting: subject).children
            .reduce(into: [String: RequestInjectable]()) { result, child in
        if let injectable = child.value as? RequestInjectable, let label = child.label {
            result[label] = injectable
        }
    }
}

extension Vapor.Request {
    func enterRequestContext<E, R>(with element: E, executing method: (E) -> EventLoopFuture<R>) -> EventLoopFuture<R> {
        inject(in: element)
        
        return method(element)
            .map { response in
                self.disconnect(from: element)
                return response
            }
    }
    
    func enterRequestContext<E, R>(with element: E, executing method: (E) -> R) -> R {
        inject(in: element)
        let response = method(element)
        disconnect(from: element)
        return response
    }
    
    private func inject<E>(in element: E) {
        // Inject all properties that can be injected using RequestInjectable
        for child in Mirror(reflecting: element).children {
            if let requestInjectable = child.value as? RequestInjectable {
                do {
                    try requestInjectable.inject(using: self)
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
