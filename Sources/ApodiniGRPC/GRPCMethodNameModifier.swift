//
//  GRPCMethodModifier.swift
//
//
//  Created by Moritz Schüll on 04.12.20.
//

import Apodini

struct GRPCMethodNameContextKey: OptionalContextKey {
    typealias Value = String
}

public struct GRPCMethodModifier<H: HandlerDefiningComponent>: HandlerModifier {
    public let component: H
    let methodName: String

    init(_ component: H, methodName: String) {
        self.component = component
        self.methodName = methodName
    }

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(GRPCMethodNameContextKey.self, value: methodName, scope: .current)
    }
}

extension HandlerDefiningComponent {
    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
    public func rpcName(_ methodName: String) -> GRPCMethodModifier<Self> {
        GRPCMethodModifier(self, methodName: methodName)
    }
}
