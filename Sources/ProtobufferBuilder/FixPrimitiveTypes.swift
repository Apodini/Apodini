//
//  File.swift
//  
//
//  Created by Nityananda on 12.12.20.
//

import Foundation

func fixPrimitiveTypes(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    guard ParticularType(node.value.typeInfo.type).isPrimitive else {
        return node
    }
    
    return Node(value: node.value, children: [])
}
