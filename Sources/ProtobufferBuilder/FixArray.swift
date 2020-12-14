//
//  File.swift
//  
//
//  Created by Nityananda on 11.12.20.
//

import Runtime

func fixArray(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    let typeInfo = node.value.typeInfo
    
    guard ParticularType(typeInfo.type).isArray,
          let first = typeInfo.genericTypes.first,
          let newNode = try EnrichedInfo.tree(first) else {
        return node
    }
    
    var newEnrichedInfo = EnrichedInfo(
        typeInfo: newNode.value.typeInfo,
        propertyInfo: node.value.propertyInfo,
        propertiesOffset: node.value.propertiesOffset
    )
    
    newEnrichedInfo.representsArrayType = true
    
    return Node(value: newEnrichedInfo, children: newNode.children)
}
