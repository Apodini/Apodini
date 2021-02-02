//
// Created by Andi on 25.12.20.
//

/// Defines a model for Relationships
public struct EndpointRelationship {
    /// The name of the Relationship
    public let name: String
    /// The destination of the Relationship
    public var destinationPath: [EndpointPath]
}


extension EndpointRelationship {
    mutating func scoped(on endpoint: AnyEndpoint) {
        destinationPath = destinationPath.scoped(on: endpoint)
    }
}

// MARK: Endpoint Relationship
extension Dictionary where Key == Operation, Value == _AnyEndpoint {
    func getScopingEndpoint() -> AnyEndpoint? {
        let order: [Operation] = [.read, .create, .update, .delete]

        for operation in order {
            if let endpoint = self[operation] {
                return endpoint
            }
        }

        return nil
    }
}
