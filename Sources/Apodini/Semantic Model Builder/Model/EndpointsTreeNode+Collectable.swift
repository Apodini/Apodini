//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
