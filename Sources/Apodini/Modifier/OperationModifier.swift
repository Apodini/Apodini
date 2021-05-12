//
//  OperationModifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

// MARK: Public API

/// Defines the Operation of a given endpoint
public enum Operation: String, CaseIterable, Hashable, CustomStringConvertible {
    /// The associated endpoint is used for a `create` operation
    case create
    /// The associated endpoint is used for a `read` operation
    case read
    /// The associated endpoint is used for a `update` operation
    case update
    /// The associated endpoint is used for a `delete` operation
    case delete

    public var description: String {
        rawValue
    }
}

public struct OperationContextKey: OptionalContextKey {
    public typealias Value = Operation
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
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(OperationContextKey.self, value: operation, scope: .current)
        component.accept(visitor)
    }
}


extension Handler {
    /// A `operation` modifier can be used to explicitly specify the `Operation` for the given `Handler`
    /// - Parameter operation: The `Operation` that is used to for the handler
    /// - Returns: The modified `Handler` with a specified `Operation`
    public func operation(_ operation: Operation) -> OperationModifier<Self> {
        OperationModifier(self, operation: operation)
    }
}
