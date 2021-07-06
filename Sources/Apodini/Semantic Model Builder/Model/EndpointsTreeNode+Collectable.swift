//
//  Created by Nityananda on 19.01.21.
//

/// Helper type which acts as a Hashable wrapper around `AnyEndpoint`
private struct AnyHashableRelationshipEndpoint: Hashable, Equatable {
    let endpoint: AnyRelationshipEndpoint
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(endpoint[AnyHandlerIdentifier.self])
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.endpoint[AnyHandlerIdentifier.self] == rhs.endpoint[AnyHandlerIdentifier.self]
    }
}

extension EndpointsTreeNode {
    func collectEndpoints() -> [AnyRelationshipEndpoint] {
        if let parent = parent {
            return parent.collectEndpoints()
        }
        return Node(root: self) { Array($0.children) }
            .map { $0.endpoints.values.map(AnyHashableRelationshipEndpoint.init) }
            .collectValues()
            .map(\.endpoint)
    }
}
