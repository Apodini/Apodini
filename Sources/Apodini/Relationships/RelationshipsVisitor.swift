//
// Created by Andreas Bauer on 18.01.21.
//

/// Ideally we would write a visitor using the
/// AssociatedTypeRequirementsKit. As this has some issues right now
/// this is a workaround for the workaround. Sadly required to be public.
public protocol RelationshipVisitor {
    /// Visits a certain instance of type `WithRelationships`.
    func visit<Relationships: WithRelationships>(_ relationships: Relationships.Type)
}

/// Something which is visitable by the `RelationshipVisitor`
public protocol RelationshipVisitable {
    /// Accepts a instance of `RelationshipVisitor`
    static func accept(_ visitor: RelationshipVisitor)
}
