//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
