//
//  File.swift
//  
//
//  Created by Nityananda on 30.11.20.
//

import Runtime

extension Tree {
    func edit<T>(
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

func fixArray(_ node: Node<TypeInfo>) -> Tree<TypeInfo> {
    guard node.value.name.prefix(while: { $0 != "<" }) == "Array" else {
        return node
    }
    
    guard let first = node.value.genericTypes.first,
          let typeInfo = try? Runtime.typeInfo(of: first) else {
        return node
    }
    
    return Node(value: node.value,
                children: [Node(value: typeInfo, children: .init())])
}
