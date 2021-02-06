//
//  Created by Lorena Schlesinger on 15.01.21.
//

import Apodini

/// Handle the `Dictionary` type.
///
/// The presence of a dictionary is mapped to the appropriate cardinality of the property with
/// `EnrichedInfo.CollectionContext`.
/// - Parameter node: An `EnrichedInfo` node.
/// - Throws: A `RuntimeError`, if `Runtime` encounters an error during reflection.
/// - Returns: An `EnrichedInfo` node.
public func handleDictionary(_ node: Node<EnrichedInfo>) throws -> Node<EnrichedInfo> {
    let typeInfo = node.value.typeInfo

    guard mangledName(of: typeInfo.type) == "Dictionary",
          let key = typeInfo.genericTypes.first, let value = typeInfo.genericTypes.last else {
        return node
    }

    let keyNode = try EnrichedInfo.node(key)
    let keyNodeType = keyNode.value.typeInfo.type
    let valueNode = try EnrichedInfo.node(value)
    
    precondition(isSupportedScalarType(keyNodeType), "Dictionary keys of type \(keyNodeType) are currently not supported. Keys must be primitives.")

    var newEnrichedInfo = EnrichedInfo(
        typeInfo: valueNode.value.typeInfo,
        propertyInfo: node.value.propertyInfo
    )
    
    newEnrichedInfo.cardinality = .zeroToMany(.dictionary(key: keyNode.value, value: valueNode.value))
    
    return Node(value: newEnrichedInfo, children: valueNode.children)
}
