//
//  Request.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import Vapor


protocol RequestInjectable {
    func inject(using request: Request) throws
    func disconnect()
}


extension Vapor.Request {
    func enterRequestContext<E, R>(with element: E, executing method: (E) -> R) -> R {
        let viewMirror = Mirror(reflecting: element)
        
        defer {
            for child in viewMirror.children {
                if let requestInjectable = child.value as? RequestInjectable {
                    requestInjectable.disconnect()
                }
            }
        }
        
        // Inject all properties that can be injected using RequestInjectable
        for child in viewMirror.children {
            if let requestInjectable = child.value as? RequestInjectable {
                do {
                    try requestInjectable.inject(using: self)
                } catch {
                    fatalError("Could not inject a value into a \(child.label ?? "UNKNOWN") property wrapper.")
                }
            }
        }
        
        return method(element)
    }
}
