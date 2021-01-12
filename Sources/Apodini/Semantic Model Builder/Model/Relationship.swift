//
// Created by Andi on 25.12.20.
//

struct EndpointRelationship { // ... to be replaced by a proper Relationship model
    let name: String
    var destinationPath: [EndpointPath]
}


extension EndpointRelationship {
    mutating func scoped(on endpoint: AnyEndpoint) {
        destinationPath = destinationPath.scoped(on: endpoint)
    }
}

// MARK: Endpoint Relationship
extension Dictionary where Key == Operation, Value == AnyEndpoint {
    func getScopingEndpoint() -> AnyEndpoint? {
        let order: [Operation] = [.read, .automatic, .create, .update, .delete]

        for operation in order {
            if let endpoint = self[operation] {
                return endpoint
            }
        }

        return nil
    }
}
