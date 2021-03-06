//
//  Created by Nityananda on 12.12.20.
//

import Apodini

/// Handle Apodini-supported primitive types.
///
/// The internal storage of primitve types is an implementation detail. Therefore, its properties
/// are not considered.
/// - Parameter node: A `ReflectionInfo` node.
/// - Returns: A `ReflectionInfo` node.
public func handlePrimitiveType(_ node: Node<ReflectionInfo>) -> Node<ReflectionInfo> {
    isSupportedScalarType(node.value.typeInfo.type)
        ? Node(value: node.value, children: [])
        : node
}
