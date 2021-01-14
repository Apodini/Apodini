//
//  File.swift
//  
//
//  Created by Nityananda on 12.01.21.
//

func handleParameter(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    guard ParticularType(node.value.typeInfo.type).isParameter,
          let first = node.value.typeInfo.genericTypes.first else {
              return node
          }
    
    let newNode = try EnrichedInfo.node(first)
    
    let newEnrichedInfo = EnrichedInfo(
        typeInfo: newNode.value.typeInfo,
        propertyInfo: node.value.propertyInfo,
        propertiesOffset: node.value.propertiesOffset
    )

    return Node(value: newEnrichedInfo, children: newNode.children)
}
