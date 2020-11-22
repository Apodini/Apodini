//
//  OperationModifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

public enum Operation: RawRepresentable {
    case CREATE
    case READ
    case UPDATE
    case DELETE

    public var rawValue: String {
        switch self {
        case .CREATE:
            return "CREATE"
        case .READ:
            return "READ"
        case .UPDATE:
            return "UPDATE"
        case .DELETE:
            return "DELETE"
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "CREATE":
            self = .CREATE
        case "READ":
            self = .READ
        case "UPDATE":
            self = .UPDATE
        case "DELETE":
            self = .DELETE
        default:
            return nil
        }
    }
}

struct OperationContextKey: ContextKey {
    static var defaultValue: Operation = .READ
    
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
        visitor.addContext(OperationContextKey.self, value: operation, scope: .environment) // TODO issue #15, change that to .nextComponent?
        component.visit(visitor)
    }
}


extension Component {
    public func operation(_ operation: Operation) -> OperationModifier<Self> {
        OperationModifier(self, operation: operation)
    }
}
