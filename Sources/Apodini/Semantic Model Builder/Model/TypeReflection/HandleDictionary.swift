//
//  Created by Lorena Schlesinger on 15.01.21.
//

import Foundation
@_implementationOnly import Runtime

func handleDictionary(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    guard ParticularType(node.value.typeInfo.type).isDictionary,
          let key = node.value.typeInfo.genericTypes.first, let value = node.value.typeInfo.genericTypes.last  else {
        return node
    }
    let keyNode = try EnrichedInfo.node(key)
    let keyNodeType = keyNode.value.typeInfo.type
    let valueNode = try EnrichedInfo.node(value)
    
    precondition(ParticularType(keyNodeType).isPrimitive, "Dictionary keys of type \(keyNodeType) are currently not supported. Keys must be primitives.")

    var newEnrichedInfo = EnrichedInfo(
        typeInfo: valueNode.value.typeInfo,
        propertyInfo: node.value.propertyInfo,
        propertiesOffset: node.value.propertiesOffset
    )
    
    newEnrichedInfo.cardinality = .zeroToMany(.dictionary(key: keyNode.value, value: valueNode.value))
    
    return Node(value: newEnrichedInfo, children: valueNode.children)
}
