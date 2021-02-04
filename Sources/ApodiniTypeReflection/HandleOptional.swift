//
//  Created by Nityananda on 21.12.20.
//

import Apodini

/// Handle the `Optional` type.
///
/// `Optional`, or the absence of values, is mapped to a propertie's cardinality. The enumeration is
/// not considered directly. Furthermore, the `Optional.WrappedValue` type is reflected.
/// - Parameter node: <#node description#>
/// - Throws: <#description#>
/// - Returns: <#description#>
public func handleOptional(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    guard isOptional(node.value.typeInfo.type),
          let first = node.value.typeInfo.genericTypes.first else {
        return node
    }

    let newNode = try EnrichedInfo.node(first)

    var newEnrichedInfo = EnrichedInfo(
        typeInfo: newNode.value.typeInfo,
        propertyInfo: node.value.propertyInfo
    )
    newEnrichedInfo.cardinality = .zeroToOne

    return Node(value: newEnrichedInfo, children: newNode.children)
}
