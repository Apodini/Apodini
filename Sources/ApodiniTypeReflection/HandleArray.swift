//
//  Created by Nityananda on 11.12.20.
//

import Apodini

/// `ArrayDidEncounterCircle` is a type to mark the repition of a type in a type hierarchy, creating
/// a circle in a structure that should remain a tree.

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
///     `ArrayDidEncounterCircle`. We can later check for this exact type and handle that case.
public enum ArrayDidEncounterCircle {}

/// Handle the `Array` type.
///
/// The presence of an array is mapped to the appropriate cardinality of the property with
/// `EnrichedInfo.CollectionContext`.
/// - Parameter node: <#node description#>
/// - Throws: A `RuntimeError`, if `Runtime` encounters an error during reflection.
/// - Returns: <#description#>
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
