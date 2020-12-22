//
// Created by Andi on 20.12.20.
//

protocol RelationshipDefinition {}

struct SomeRelationshipReference<From, To: Identifiable>: RelationshipDefinition {
    var name: String
    var type: To.Type
    var keyPath: KeyPath<From, To.ID>

    init(to type: To.Type = To.self, at keyPath: KeyPath<From, To.ID>, as name: String) {
        self.name = name
        self.type = type
        self.keyPath = keyPath

        if name == "self" {
            fatalError("The relationship name 'self' is reserved. To model relationship inheritance please use `Inherits`!")
        }
    }

    func identifier(for from: From) -> To.ID {
        from[keyPath: keyPath]
    }
}

struct SomeRelationshipInheritance<From, To: Identifiable>: RelationshipDefinition {
    let name: String = "self" // reserved relationship name to signal inheritance
    var type: To.Type
    var keyPath: KeyPath<From, To.ID>

    init(from type: To.Type = To.self, at keyPath: KeyPath<From, To.ID>) {
        self.type = type
        self.keyPath = keyPath
    }

    func identifier(for from: From) -> To.ID {
        from[keyPath: keyPath]
    }
}

protocol WithRelationships {
    typealias References<To: Identifiable> = SomeRelationshipReference<Self, To>
    typealias Inherits<To: Identifiable> = SomeRelationshipInheritance<Self, To>
    associatedtype Relationships: RelationshipDefinition
    static var relationships: Relationships { get }
}
