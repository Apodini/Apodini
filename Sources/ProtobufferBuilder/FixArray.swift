//
//  File.swift
//  
//
//  Created by Nityananda on 11.12.20.
//

import Runtime

func fixArray(_ node: Node<TypeInfo>) throws -> Tree<TypeInfo> {
    guard ParticularType(node.value.type).isArray,
          let first = node.value.genericTypes.first else {
        return node
    }
    
    return Node(value: try Runtime.typeInfo(of: first),
                children: [])
}
