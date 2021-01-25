//
//  Created by Nityananda on 07.01.21.
//

extension EndpointsTreeNode: CustomDebugStringConvertible {
    var debugDescription: String {
        if let parent = parent {
            return parent.debugDescription
        }
        
        let node = Node(root: self) { root in
            Array(root.children)
        }
        .map { value -> String in
            let operations = value.endpoints
                .map { key, value -> String in
                    "- \(key): \(value.description) [\(value.identifier.rawValue)]\n"
                }
                .joined()
            
            return """
                \(value.path.description)/
                \(operations)
                """
        }
        
        return node.description
    }
}
