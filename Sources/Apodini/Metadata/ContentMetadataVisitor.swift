//
// Created by Andreas Bauer on 17.05.21.
//

@_implementationOnly import AssociatedTypeRequirementsVisitor

protocol ContentMetadataVisitor: AssociatedTypeRequirementsTypeVisitor {
    associatedtype Visitor = ContentMetadataVisitor
    associatedtype Input = Content
    associatedtype Output

    func callAsFunction<T: Content>(_ type: T.Type) -> Output
}

private struct TestContent: Content {}

extension ContentMetadataVisitor {
    @inline(never)
    @_optimize(none)
    func _test() { // swiftlint:disable:this identifier_name
        _ = self(TestContent.self) as Output
    }
}
 
struct StandardContentMetadataVisitor: ContentMetadataVisitor {
    let visitor: SyntaxTreeVisitor

    func callAsFunction<T: Content>(_ type: T.Type) {
        type.metadata.accept(visitor)
    }
}
