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

public struct GRPCServiceModifier<H: _Handler>: HandlerModifier {
    public let component: H
    let serviceName: String

    init(_ component: H, serviceName: String) {
        self.component = component
        self.serviceName = serviceName
    }

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(GRPCServiceNameContextKey.self, value: serviceName, scope: .current)
    }
}

extension _Handler {
    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
    public func serviceName(_ serviceName: String) -> GRPCServiceModifier<Self> {
        GRPCServiceModifier(self, serviceName: serviceName)
    }
}
