//
// Created by Andreas Bauer on 18.01.21.
//

@_implementationOnly import AssociatedTypeRequirementsVisitor

protocol RelationshipsVisitor: AssociatedTypeRequirementsTypeVisitor {
    associatedtype Visitor = RelationshipsVisitor
    associatedtype Input = WithRelationships
    associatedtype Output

    func callAsFunction<T: WithRelationships>(_ type: T.Type) -> Output
}

private struct TestWithRelationship: WithRelationships {
    static var relationships: Relationships {
        Relationship<String>(name: "test")
    }
}

extension RelationshipsVisitor {
    @inline(never)
    @_optimize(none)
    func _test() { // swiftlint:disable:this identifier_name
        _ = self(TestWithRelationship.self)
    }
}

struct StandardRelationshipsVisitor: RelationshipsVisitor {
    let visitor: SyntaxTreeVisitor

    func callAsFunction<T: WithRelationships>(_ type: T.Type) {
        for definition in type.relationships {
            definition.accept(visitor)
        }
    }
}
