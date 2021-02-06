//
//  Created by Nityananda on 11.12.20.
//

// swiftlint:disable missing_docs

public enum ArrayDidEncounterCircle {}

public func handleArray(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    let typeInfo = node.value.typeInfo

    guard mangledName(of: typeInfo.type) == "Array",
          let first = typeInfo.genericTypes.first else {
        return node
    }

    let newTree = try EnrichedInfo.node(first)
        .edited { node in
            // Check if a type is repeated and if it comes true, inject a _trap_.
            node.value.typeInfo.type == typeInfo.type
                ? try EnrichedInfo.node(ArrayDidEncounterCircle.self)
                : node
        }

    guard let newNode = newTree else {
        return nil
    }

    var newEnrichedInfo = EnrichedInfo(
        typeInfo: newNode.value.typeInfo,
        propertyInfo: node.value.propertyInfo
    )
    newEnrichedInfo.cardinality = .zeroToMany(.array)

    return Node(value: newEnrichedInfo, children: newNode.children)
}
