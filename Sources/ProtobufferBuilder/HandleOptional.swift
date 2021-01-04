//
//  File.swift
//  
//
//  Created by Nityananda on 21.12.20.
//

@_implementationOnly import Runtime

func handleOptional(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    guard ParticularType(node.value.typeInfo.type).isOptional,
          let first = node.value.typeInfo.genericTypes.first else {
        return node
    }
    
    let newNode = try EnrichedInfo.node(first)
    
    var newEnrichedInfo = EnrichedInfo(
        typeInfo: newNode.value.typeInfo,
        propertyInfo: node.value.propertyInfo,
        propertiesOffset: node.value.propertiesOffset
    )
    newEnrichedInfo.cardinality = .zeroToOne
    
    return Node(value: newEnrichedInfo, children: newNode.children)
}
