//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

struct RelationshipNameContextKey: OptionalContextKey {
    typealias Value = String
}

public struct RelationshipNameModifier: PathComponentModifier {
    let pathComponent: any _PathComponent
    let relationshipName: String

    init(_ pathComponent: any PathComponent, relationshipName: String) {
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
