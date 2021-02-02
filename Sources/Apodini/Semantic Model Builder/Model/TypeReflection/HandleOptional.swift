//
//  Created by Nityananda on 21.12.20.
//

func handleOptional(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    guard isOptional(node.value.typeInfo.type),
          let first = node.value.typeInfo.genericTypes.first else {
        return node
    }

    let newNode = try EnrichedInfo.node(first)

    var newEnrichedInfo = EnrichedInfo(
            typeInfo: newNode.value.typeInfo,
            propertyInfo: node.value.propertyInfo,
            runtimePropertyInfo: node.value.runtimePropertyInfo
    )
    newEnrichedInfo.cardinality = .zeroToOne

    return Node(value: newEnrichedInfo, children: newNode.children)
}
