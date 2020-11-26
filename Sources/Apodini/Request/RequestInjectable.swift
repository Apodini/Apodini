//
//  Request.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import Vapor
import Runtime


protocol RequestInjectable {
    mutating func inject(using request: Vapor.Request, with decoder: SemanticModelBuilder?) throws
}

extension Vapor.Request {
    func enterRequestContext<E, R>(with element: E, using decoder: SemanticModelBuilder? = nil, executing method: (E) -> EventLoopFuture<R>)
    -> EventLoopFuture<R> {
        var element = element
        inject(in: &element, using: decoder)
        
        return method(element)
    }
    
    func enterRequestContext<E, R>(with element: E, using decoder: SemanticModelBuilder? = nil, executing method: (E) -> R) -> R {
        var element = element
        inject(in: &element, using: decoder)
        return method(element)
    }
    
    private func inject<E>(in element: inout E, using decoder: SemanticModelBuilder? = nil) {
        // Inject all properties that can be injected using RequestInjectable
        do {
            let info = try typeInfo(of: E.self)
            
            for property in info.properties {
                if var child = (try property.get(from: element)) as? RequestInjectable {
                    assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "RequestInjectable \(property.name) on Component \(info.name) must be a struct.")
                    try child.inject(using: self, with: decoder)
                    try property.set(value: child, on: &element)
                }
            }
        } catch {
            fatalError("Injecting into element \(element) failed.")
        }
    }
}
