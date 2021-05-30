@_implementationOnly import AssociatedTypeRequirementsVisitor


extension SyntaxTreeVisitor {
    enum UnsafeVisitAny: Swift.Error {
        case attemptedToVisitNoneComponent(Any, visitor: SyntaxTreeVisitor)
    }

    
    /// Allows you to visit an object that you know implements Component, even if you don't know the concrete type at compile time.
    func unsafeVisitAny(_ value: Any) throws {
        if StandardComponentVisitor(visitor: self)(value) == nil {
            throw UnsafeVisitAny.attemptedToVisitNoneComponent(value, visitor: self)
        }
    }
}


private protocol ComponentAssociatedTypeRequirementsVisitor: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = ComponentAssociatedTypeRequirementsVisitor
    associatedtype Input = Component
    associatedtype Output

    func callAsFunction<T: Component>(_ value: T) -> Output
}

extension ComponentAssociatedTypeRequirementsVisitor {
    @inline(never)
    @_optimize(none)
    fileprivate func _test() {
        _ = self(EmptyComponent())
    }
}

private struct StandardComponentVisitor: ComponentAssociatedTypeRequirementsVisitor {
    let visitor: SyntaxTreeVisitor

    func callAsFunction<T: Component>(_ value: T) {
        value.accept(visitor)
    }
}
