//
//  Created by Nityananda on 12.12.20.
//

import Apodini

/// Handle Apodini-supported primitive types.
///
/// The storage of primitve types is an implementation detail. Therefore, its properties are not
/// considered.
/// - Parameter node: An `EnrichedInfo` node.
/// - Returns: An `EnrichedInfo` node.
public func handlePrimitiveType(_ node: Node<EnrichedInfo>) -> Node<EnrichedInfo> {
    isSupportedScalarType(node.value.typeInfo.type)
        ? Node(value: node.value, children: [])
        : node
}
