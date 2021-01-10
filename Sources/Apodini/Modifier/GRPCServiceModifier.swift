//
//  GRPCServiceModifier.swift
//
//
//  Created by Moritz Schüll on 04.12.20.
//

struct GRPCServiceNameContextKey: ContextKey {
    static var defaultValue = ""

    static func reduce(value: inout String, nextValue: () -> String) {
        value = nextValue()
    }
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
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(GRPCServiceNameContextKey.self, value: serviceName, scope: .nextHandler)
        component.accept(visitor)
    }
}

extension Handler {
    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
    public func serviceName(_ serviceName: String) -> GRPCServiceModifier<Self> {
        GRPCServiceModifier(self, serviceName: serviceName)
    }
}
