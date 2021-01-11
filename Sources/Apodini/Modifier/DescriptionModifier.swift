//
// Created by Lorena Schlesinger on 10.01.21.
//

struct DescriptionContextKey: ContextKey {
    static var defaultValue = ""

    static func reduce(value: inout String, nextValue: () -> String) {
        value = nextValue()
    }
}

public struct DescriptionModifier<H: Handler>: HandlerModifier {
    public let component: H
    let description: String

    init(_ component: H, description: String) {
        self.component = component
        self.description = description
    }
}

extension DescriptionModifier: SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(DescriptionContextKey.self, value: description, scope: .nextHandler)
        component.accept(visitor)
    }
}

extension Handler {
    /// A `description` modifier can be used to explicitly specify the `description` for the given `Handler`
    /// - Parameter description: The `description` that is used to for the handler
    /// - Returns: The modified `Handler` with a specified `description`
    public func description(_ description: String) -> DescriptionModifier<Self> {
        DescriptionModifier(self, description: description)
    }
}
