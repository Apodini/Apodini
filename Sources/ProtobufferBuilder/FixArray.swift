//
//  File.swift
//  
//
//  Created by Nityananda on 11.12.20.
//

@_implementationOnly import Runtime

enum ProtobufferBuilderDidEncounterCircle {}

func fixArray(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    let typeInfo = node.value.typeInfo
    
    guard ParticularType(typeInfo.type).isArray,
          let first = typeInfo.genericTypes.first else {
        return node
    }
    
    let newTree = try EnrichedInfo.node(first)
        .edited { node in
            /// Check if a type is repeated and if it comes true, inject a _trap_.
            node.value.typeInfo.type == typeInfo.type
                ? try EnrichedInfo.node(ProtobufferBuilderDidEncounterCircle.self)
                : node
        }
    
    guard let newNode = newTree else { return nil }
    
    var newEnrichedInfo = EnrichedInfo(
        typeInfo: newNode.value.typeInfo,
        propertyInfo: node.value.propertyInfo,
        propertiesOffset: node.value.propertiesOffset
    )
    newEnrichedInfo.cardinality = .zeroToMany
    
    return Node(value: newEnrichedInfo, children: newNode.children)
}
