//
// Created by Andreas Bauer on 05.01.21.
//

struct RelationshipNameContextKey: OptionalContextKey {
    typealias Value = String
}

public struct RelationshipNameModifier: PathComponentModifier {
    let pathComponent: _PathComponent
    let relationshipName: String

    init(_ pathComponent: PathComponent, relationshipName: String) {
        self.pathComponent = pathComponent.toInternal()
        self.relationshipName = relationshipName
    }

    func accept<Parser: PathComponentParser>(_ parser: inout Parser) {
        parser.addContext(RelationshipNameContextKey.self, value: relationshipName)
        pathComponent.accept(&parser)
    }
}

extension PathComponent {
    /// A `RelationshipNameModifier` can be used to specify a custom name for the Relationship
    /// defined under this `PathComponent`.
    /// - Returns: The modified `PathComponent` with a altered relationship name.
    public func relationship(name: String) -> RelationshipNameModifier {
        RelationshipNameModifier(self, relationshipName: name)
    }
}
