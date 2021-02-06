//
//  GRPCServiceModifier.swift
//
//
//  Created by Moritz Schüll on 04.12.20.
//

import Apodini


struct GRPCServiceNameContextKey: OptionalContextKey {
    typealias Value = String
}

public struct GRPCServiceModifier<H: Handler>: HandlerModifier {
    public let component: H
    let serviceName: String

    init(_ component: H, serviceName: String) {
        self.component = component
        self.serviceName = serviceName
    }
}

extension GRPCServiceModifier: SyntaxTreeVisitable {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(GRPCServiceNameContextKey.self, value: serviceName, scope: .current)
        component.accept(visitor)
    }
}

extension Handler {
    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
    public func serviceName(_ serviceName: String) -> GRPCServiceModifier<Self> {
        GRPCServiceModifier(self, serviceName: serviceName)
    }
}
