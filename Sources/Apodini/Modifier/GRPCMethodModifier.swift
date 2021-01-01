//
//  GRPCMethodModifier.swift
//
//
//  Created by Moritz Schüll on 04.12.20.
//

struct GRPCMethodNameContextKey: ContextKey {
    static var defaultValue = ""

    static func reduce(value: inout String, nextValue: () -> String) {
        value = nextValue()
    }
}

public struct GRPCMethodModifier<H: Handler>: HandlerModifier {
    public let component: H
    let methodName: String

    init(_ component: H, methodName: String) {
        self.component = component
        self.methodName = methodName
    }
}

extension GRPCMethodModifier: SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(GRPCMethodNameContextKey.self, value: methodName, scope: .nextComponent)
        component.accept(visitor)
    }
}

extension Handler {
    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
    public func rpcName(_ methodName: String) -> GRPCMethodModifier<Self> {
        GRPCMethodModifier(self, methodName: methodName)
    }
}
