//
//  Created by Nityananda on 21.12.20.
//

import Apodini
import ApodiniUtils

/// Handle the `Optional` type.
///
/// An `Optional`, or the absence of values, is mapped to the `ReflectionInfo`'s cardinality. The
/// enumeration `Optional` is not considered directly. Furthermore, the `Optional.WrappedValue` type
/// is reflected.
/// - Parameter node: A `ReflectionInfo` node.
/// - Throws: A `RuntimeError`, if `Runtime` encounters an error during reflection.
/// - Returns: A `ReflectionInfo` node.
public func handleOptional(_ node: Node<ReflectionInfo>) throws -> Node<ReflectionInfo> {
    guard isOptional(node.value.typeInfo.type),
          let first = node.value.typeInfo.genericTypes.first else {
        return node
    }

    let newNode = try ReflectionInfo.node(first)

    var newReflectionInfo = ReflectionInfo(
        typeInfo: newNode.value.typeInfo,
        propertyInfo: node.value.propertyInfo
    )
    newReflectionInfo.cardinality = .zeroToOne

    return Node(value: newReflectionInfo, children: newNode.children)
}
