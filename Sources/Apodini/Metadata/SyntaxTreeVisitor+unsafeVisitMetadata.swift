//
// Created by Andreas Bauer on 17.05.21.
//

@_implementationOnly import AssociatedTypeRequirementsVisitor


extension SyntaxTreeVisitor {
    enum UnsafeVisitMetadata: Swift.Error {
        case attemptedToVisitNoneMetadata(Any, visitor: SyntaxTreeVisitor)
    }

    func unsafeVisitMetadata(_ value: Any) throws {
        let visitor = StandardAnyMetadataVisitor(visitor: self)
        if visitor(value) == nil {
            throw UnsafeVisitMetadata.attemptedToVisitNoneMetadata(value, visitor: self)
        }
    }
}


private protocol AnyMetadataVisitor: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = AnyMetadataVisitor
    associatedtype Input = AnyMetadata
    associatedtype Output

    func callAsFunction<T: AnyMetadata>(_ value: T) -> Output
}

private struct TestMetadata: AnyMetadata {
    func accept(_ visitor: SyntaxTreeVisitor) {}
}

extension AnyMetadataVisitor {
    @inline(never)
    @_optimize(none)
    fileprivate func _test() {
        _ = self(TestMetadata())
    }
}

private struct StandardAnyMetadataVisitor: AnyMetadataVisitor {
    let visitor: SyntaxTreeVisitor

    func callAsFunction<T: AnyMetadata>(_ value: T) {
        value.accept(visitor)
    }
}
