import Foundation
import AssociatedTypeRequirementsVisitor

extension SyntaxTreeVisitor {
    enum Error: Swift.Error {
        case attemptedToVisitNoneComponent(Any, visitor: SyntaxTreeVisitor)
    }

    /**
        Allows you to visit an object that you know implements Component, even if you don't know the concrete type at compile time.
     */
    func unsafeVisitAny(_ value: Any) throws {
        var didVisitAsEndpointProvidingNode = false
        EndpointProviderVisitorHelperImpl(visitor: self) {
            didVisitAsEndpointProvidingNode = true
        }(value)
        
        guard !didVisitAsEndpointProvidingNode else {
            return
        }
        
        var didVisitAsEndpointNode = false
        EndpointVisitorHelperImpl(visitor: self) {
            didVisitAsEndpointNode = true
        }(value)
        
        guard !didVisitAsEndpointNode else {
            return
        }
        
        throw Error.attemptedToVisitNoneComponent(value, visitor: self)
    }
}




private protocol EndpointProviderVisitorHelperImplBase: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = EndpointProviderVisitorHelperImplBase
    associatedtype Input = EndpointProvidingNode
    associatedtype Output

    func callAsFunction<T: EndpointProvidingNode>(_ value: T) -> Output
}

private struct EndpointProviderVisitorHelperImpl: EndpointProviderVisitorHelperImplBase {
    let visitor: SyntaxTreeVisitor
    let didVisitHandler: () -> Void

    func callAsFunction<T: EndpointProvidingNode>(_ value: T) {
        value.visit(visitor)
        didVisitHandler()
    }
}




private protocol EndpointVisitorHelperImplBase: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = EndpointVisitorHelperImplBase
    associatedtype Input = EndpointNode
    associatedtype Output

    func callAsFunction<T: EndpointNode>(_ value: T) -> Output
}

private struct EndpointVisitorHelperImpl: EndpointVisitorHelperImplBase {
    let visitor: SyntaxTreeVisitor
    let didVisitHandler: () -> Void

    func callAsFunction<T: EndpointNode>(_ value: T) {
        value.visit(visitor)
        didVisitHandler()
    }
}
