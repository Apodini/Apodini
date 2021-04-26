import Apodini

/// Context key used to register operation name used to call the handler
public struct PallidorContextKey: OptionalContextKey {
    public typealias Value = String
}

/// Modfier to to allow specifying a operation name for the handler
public struct PallidorModifier<H: Handler>: HandlerModifier {
    public let component: H
    let operationName: String

    init(_ component: H, operationName: String) {
        self.component = component
        self.operationName = operationName
    }
}

extension PallidorModifier: SyntaxTreeVisitable {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(PallidorContextKey.self, value: operationName, scope: .current)
        component.accept(visitor)
    }
}

extension Handler {
    /// A `operationName` modifier can be used to explicitly specify a suggested operation name for the given `Handler`
    /// - Parameter operationName: The name of the operation (method) suggested for the clients to name the calling API method
    /// - Returns: The modified `Handler` with specific `operationName`
    public func pallidor(_ operationName: String) -> PallidorModifier<Self> {
        PallidorModifier(self, operationName: operationName)
    }
}
