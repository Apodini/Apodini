//
//  File.swift
//
//
//  Created by Nityananda on 12.12.20.
//

func handlePrimitiveType(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    ParticularType(node.value.typeInfo.type).isPrimitive
            ? Node(value: node.value, children: [])
            : node
}
