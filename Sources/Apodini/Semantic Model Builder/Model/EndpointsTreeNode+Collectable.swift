//
//  Created by Nityananda on 19.01.21.
//

/// Helper type which acts as a Hashable wrapper around `AnyEndpoint`
private struct AnyHashableEndpoint: Hashable, Equatable {
    let endpoint: AnyEndpoint
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(endpoint.identifier)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.endpoint.identifier == rhs.endpoint.identifier
    }
}

extension EndpointsTreeNode {
    func collectAllEndpoints() -> [AnyEndpoint] {
        if let parent = parent {
            return parent.collectEndpoints()
        }
        
        let node = Node(root: self) { root in
            Array(root.children)
        }
        .map { node in
            node.endpoints.values.map(AnyHashableEndpoint.init)
        }
        
        return node
            .collectValues()
            .map(\.endpoint)
    }
}
