//
//  File.swift
//  
//
//  Created by Nityananda on 21.12.20.
//

@_implementationOnly import Runtime

func fixOptional(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    let typeInfo = node.value.typeInfo
    
    guard ParticularType(typeInfo.type).isOptional,
          let first = typeInfo.genericTypes.first,
          let newNode = try EnrichedInfo.tree(first) else {
        return node
    }
    
    var newEnrichedInfo = EnrichedInfo(
        typeInfo: newNode.value.typeInfo,
        propertyInfo: node.value.propertyInfo,
        propertiesOffset: node.value.propertiesOffset
    )
    
    newEnrichedInfo.cardinality = .zeroToOne
    
    return Node(value: newEnrichedInfo, children: newNode.children)
}
