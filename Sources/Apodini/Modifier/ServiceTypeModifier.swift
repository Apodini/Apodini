//
//  ServiceTypeModifier.swift
//  
//
//  Created by Moritz Schüll on 07.01.21.
//

import Foundation

/// Used to explicitly define the communicacational
/// pattern thta is expressed by a `Handler`.
public enum ServiceType {
    /// Simple request-response
    case unary
    /// Client-side streaming, service-side unary
    case clientStreaming
    /// Client-side unary, service-side streaming
    case serviceStreaming
    /// Client-side and service-side streaming
    case bidirectional
}

struct ServiceTypeContextKey: ContextKey {
    static var defaultValue: ServiceType = .unary

    static func reduce(value: inout ServiceType, nextValue: () -> ServiceType) {
        value = nextValue()
    }
}

public struct ServiceTypeModifier<H: Handler>: HandlerModifier {
    public let component: H
    let serviceType: ServiceType

    init(_ component: H, serviceType: ServiceType) {
        self.component = component
        self.serviceType = serviceType
    }
}

extension ServiceTypeModifier: SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(ServiceTypeContextKey.self, value: serviceType, scope: .nextHandler)
        component.accept(visitor)
    }
}

extension Handler {
    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
    public func serviceType(_ serviceType: ServiceType) -> ServiceTypeModifier<Self> {
        ServiceTypeModifier(self, serviceType: serviceType)
    }
}
