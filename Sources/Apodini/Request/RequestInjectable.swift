//
//  Request.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import Runtime


protocol RequestInjectable {
    mutating func inject(using request: Request, with decoder: RequestInjectableDecoder?) throws
}

protocol RequestInjectableDecoder {
    func decode<T: Decodable>(_ type: T.Type, from request: Request) throws -> T?
}

private func extractRequestInjectables(from subject: Any) -> [String: RequestInjectable] {
    Mirror(reflecting: subject).children.reduce(into: [String: RequestInjectable]()) { result, child in
        if let injectable = child.value as? RequestInjectable, let label = child.label {
            result[label] = injectable
        }
    }
}

extension Component {
    func extractRequestInjectables() -> [String: RequestInjectable] {
        Apodini.extractRequestInjectables(from: self)
    }
}
extension AnyResponseTransformer {
    func extractRequestInjectables() -> [String: RequestInjectable] {
        Apodini.extractRequestInjectables(from: self)
    }
}

extension Request {
    func enterRequestContext<E, R>(with element: E, using decoder: RequestInjectableDecoder? = nil, executing method: (E) -> EventLoopFuture<R>)
                    -> EventLoopFuture<R> {
        var element = element
        inject(in: &element, using: decoder)

        return method(element)
    }

    func enterRequestContext<E, R>(with element: E, using decoder: RequestInjectableDecoder? = nil, executing method: (E) -> R) -> R {
        var element = element
        inject(in: &element, using: decoder)
        return method(element)
    }
    
    private func inject<E>(in element: inout E, using decoder: RequestInjectableDecoder? = nil) {
        // Inject all properties that can be injected using RequestInjectable
        do {
            let info = try typeInfo(of: E.self)
            
            for property in info.properties {
                if var child = (try property.get(from: element)) as? RequestInjectable {
                    assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "RequestInjectable \(property.name) on Component \(info.name) must be a struct")
                    try child.inject(using: self, with: decoder)
                    try property.set(value: child, on: &element)
                }
            }
        } catch {
            fatalError("Injecting into element \(element) failed.")
        }
    }
}
