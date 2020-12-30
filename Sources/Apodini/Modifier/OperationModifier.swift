//
//  OperationModifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

/// Defines the Operation of a given endpoint
public enum Operation {
    /// This operation is the default for every endpoint.
    case automatic
    /// The associated endpoint is used for a `create` operation
    case create
    /// The associated endpoint is used for a `read` operation
    case read
    /// The associated endpoint is used for a `update` operation
    case update
    /// The associated endpoint is used for a `delete` operation
    case delete
}

struct OperationContextKey: ContextKey {
    static var defaultValue: Operation = .automatic
    
    static func reduce(value: inout Operation, nextValue: () -> Operation) {
        value = nextValue()
    }
}


public struct OperationModifier<H: Handler>: HandlerModifier {
    public let component: H
    let operation: Operation
    
    init(_ component: H, operation: Operation) {
        self.component = component
        self.operation = operation
    }
}


extension OperationModifier: SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(OperationContextKey.self, value: operation, scope: .nextComponent)
        component.accept(visitor)
    }
}


extension Handler {
    /// A `operation` modifier can be used to explicitly specify the `Operation` for the given `Component`
    /// - Parameter operation: The `Operation` that is used to for the component
    /// - Returns: The modified `Component` with a specified `Operation`
    public func operation(_ operation: Operation) -> OperationModifier<Self> {
        OperationModifier(self, operation: operation)
    }
}
