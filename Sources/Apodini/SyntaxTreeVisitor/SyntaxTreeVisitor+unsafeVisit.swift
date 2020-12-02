import Foundation
import AssociatedTypeRequirementsVisitor

extension SynaxTreeVisitor {
    enum Error: Swift.Error {
        case attemptedToVisitNoneComponent(Any, visitor: SynaxTreeVisitor)
    }

    /**
        Allows you to visit an object that you know implements Component, even if you don't know the concrete type at compile time.
     */
    func unsafeVisitAny(_ value: Any) throws {
        let associatedTypeRequirementsVisitor = StandardComponentVisitor(visitor: self)
        if associatedTypeRequirementsVisitor(value) == nil {
            throw Error.attemptedToVisitNoneComponent(value, visitor: self)
        }
    }
}

private protocol ComponentAssociatedTypeRequirementsVisitor: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = ComponentAssociatedTypeRequirementsVisitor
    associatedtype Input = Component
    associatedtype Output

    func callAsFunction<T: Component>(_ value: T) -> Output
}

private struct StandardComponentVisitor: ComponentAssociatedTypeRequirementsVisitor {
    let visitor: SynaxTreeVisitor

    func callAsFunction<T: Component>(_ value: T) {
        value.visit(visitor)
    }
}
