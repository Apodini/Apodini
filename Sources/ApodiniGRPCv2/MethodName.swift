import Apodini


struct GRPCv2MethodNameContextKey: OptionalContextKey {
    typealias Value = String
}


public struct GRPCv2MethodModifier<H: Handler>: HandlerModifier {
    public let component: H
    let methodName: String
    
    init(_ component: H, methodName: String) {
        self.component = component
        self.methodName = methodName
    }
    
    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(GRPCv2MethodNameContextKey.self, value: methodName, scope: .current)
    }
}


extension Handler {
    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
    public func gRPCv2methodName(_ methodName: String) -> GRPCv2MethodModifier<Self> { // TODO drop the v2
        .init(self, methodName: methodName)
    }
}

