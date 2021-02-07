//
//  Created by Nityananda on 11.12.20.
//

import Apodini

/// `HandleArrayDidEncounterCircle` is a type to mark the repetition of a type in a type hierarchy,
/// creating a circle in a structure that should remain a tree.
///
/// - **Example:**
///     Let's assume the following type:
///     ```
///     struct Node {
///         let children: [Node]
///     }
///     ```
///     First of all, it is valid, because it's size is not infinite: we can initialize
///     `Node(children: [])`.
///
///     However, this implementation of type reflection will (1) reflect `Node`, (2) reflect its
///     properties and their types, e.g., `children: [Node]`, (3) the `Array` is checked for its
///     `Element` type, which is again a `Node`. (4) We encounter a circle, which is marked with
///     `HandleArrayDidEncounterCircle`. We can later check for this exact type and handle that case.
public enum HandleArrayDidEncounterCircle {}

/// Handle the `Array` type.
///
/// The presence of an array is mapped to the `ReflectionInfo`'s cardinality with
/// `ReflectionInfo.CollectionContext`.
/// - Parameter node: A `ReflectionInfo` node.
/// - Throws: A `RuntimeError`, if `Runtime` encounters an error during reflection.
/// - Returns: A `ReflectionInfo` tree.
public func handleArray(_ node: Node<ReflectionInfo>) throws -> Tree<ReflectionInfo> {
    let typeInfo = node.value.typeInfo

    guard mangledName(of: typeInfo.type) == "Array",
          let first = typeInfo.genericTypes.first else {
        return node
    }

    let newTree = try ReflectionInfo.node(first)
        .edited { node in
            // Check if a type is repeated and if it comes true, inject a _trap_.
            node.value.typeInfo.type == typeInfo.type
                ? try ReflectionInfo.node(HandleArrayDidEncounterCircle.self)
                : node
        }

    guard let newNode = newTree else {
        return nil
    }

    var newReflectionInfo = ReflectionInfo(
        typeInfo: newNode.value.typeInfo,
        propertyInfo: node.value.propertyInfo
    )
    newReflectionInfo.cardinality = .zeroToMany(.array)

    return Node(value: newReflectionInfo, children: newNode.children)
}
