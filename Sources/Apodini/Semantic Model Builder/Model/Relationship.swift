//
// Created by Andi on 25.12.20.
//

struct EndpointRelationship { // ... to be replaced by a proper Relationship model
    let name: String
    var destinationPath: [EndpointPath]
}


extension EndpointRelationship {
    func scoped(on endpoint: AnyEndpoint) -> EndpointRelationship {
        var relationship = self
        relationship.destinationPath = relationship.destinationPath.scoped(on: endpoint)
        return relationship
    }
}

extension Array where Element == EndpointRelationship {
    func scoped(on endpoint: AnyEndpoint) -> [EndpointRelationship] {
        map { relationship in
            relationship.scoped(on: endpoint)
        }
    }
}
