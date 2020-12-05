//
//  File.swift
//  
//
//  Created by Nityananda on 30.11.20.
//

import Runtime

extension Tree {
    func edited<T>(
        _ transform: (Node<T>) throws -> Tree<T>
    ) rethrows -> Tree<T> where Wrapped == Node<T> {
        guard let node = self,
              let intermediate = try transform(node) else { return nil }
        
        let children = try intermediate.children.compactMap { child in
            try transform(child)
        }
        
        return Node(value: intermediate.value, children: children)
    }
}

// MARK: - Fix Array

func fixArray(_ node: Node<TypeInfo>) throws -> Tree<TypeInfo> {
    guard node.value.isArray,
          let first = node.value.genericTypes.first else {
        return node
    }
    
    return Node(value: try Runtime.typeInfo(of: first),
                children: [])
}
