//
//  OperationModifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

/// Defines the Operation of a given endpoint
public enum Operation {
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
    static var defaultValue: Operation = .read
    
    static func reduce(value: inout Operation, nextValue: () -> Operation) {
        value = nextValue()
    }
}

public struct OperationModifier<ModifiedComponent: Component>: Modifier {
    let component: ModifiedComponent
    let operation: Operation
    
    
    init(_ component: ModifiedComponent, operation: Operation) {
        self.component = component
        self.operation = operation
    }
}


extension OperationModifier: Visitable {
    func visit(_ visitor: SynaxTreeVisitor) {
        visitor.addContext(OperationContextKey.self, value: operation, scope: .nextComponent)
        component.visit(visitor)
    }
}


extension Component {
    /// Sets the `Operation` for the given `Component`
    public func operation(_ operation: Operation) -> OperationModifier<Self> {
        OperationModifier(self, operation: operation)
    }
}
