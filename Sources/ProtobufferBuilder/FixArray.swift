//
//  File.swift
//  
//
//  Created by Nityananda on 11.12.20.
//

@_implementationOnly import Runtime

struct DidFindRecursionError: Error {}

func fixArray(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    let typeInfo = node.value.typeInfo
    
    guard ParticularType(typeInfo.type).isArray,
          let first = typeInfo.genericTypes.first,
          let newNode = try EnrichedInfo.tree(first) else {
        return node
    }
    
    if newNode.contains(where: { enrichedInfo in
        enrichedInfo.typeInfo.type == typeInfo.type
    }) {
        throw DidFindRecursionError()
    }
    
    var newEnrichedInfo = EnrichedInfo(
        typeInfo: newNode.value.typeInfo,
        propertyInfo: node.value.propertyInfo,
        propertiesOffset: node.value.propertiesOffset
    )
    
    newEnrichedInfo.cardinality = .zeroToMany
    
    return Node(value: newEnrichedInfo, children: newNode.children)
}
