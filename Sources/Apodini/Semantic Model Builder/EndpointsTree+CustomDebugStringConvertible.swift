//
//  Created by Nityananda on 07.01.21.
//

extension EndpointsTreeNode: CustomDebugStringConvertible {
    public var debugDescription: String {
        if let parent = parent {
            return parent.debugDescription
        }
        
        let node = Node(root: self) { root in
            Array(root.children)
        }
        .map { value -> String in
            let operations = value.endpoints
                .map { key, value -> String in
                    "- \(key): \(value.description) [\(value[AnyHandlerIdentifier.self].rawValue)]\n"
                }
                .joined()
            
            return """
                \(value.storedPath.description)/
                \(operations)
                """
        }
        
        return "\n" + node.description
    }
}
