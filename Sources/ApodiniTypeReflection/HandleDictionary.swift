//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniUtils

/// Handle the `Dictionary` type.
///
/// The presence of a dictionary is mapped to the `ReflectionInfo`'s cardinality with
/// `ReflectionInfo.CollectionContext`.
/// - Parameter node: A `ReflectionInfo` node.
/// - Throws: A `RuntimeError`, if `Runtime` encounters an error during reflection.
/// - Returns: A `ReflectionInfo` node.
public func handleDictionary(_ node: Node<ReflectionInfo>) throws -> Node<ReflectionInfo> {
    let typeInfo = node.value.typeInfo

    guard mangledName(of: typeInfo.type) == "Dictionary",
          let key = typeInfo.genericTypes.first, let value = typeInfo.genericTypes.last else {
        return node
    }

    let keyNode = try ReflectionInfo.node(key)
    let keyNodeType = keyNode.value.typeInfo.type
    let valueNode = try ReflectionInfo.node(value)
    
    precondition(isSupportedScalarType(keyNodeType), "Dictionary keys of type \(keyNodeType) are currently not supported. Keys must be primitives.")

    var newReflectionInfo = ReflectionInfo(
        typeInfo: valueNode.value.typeInfo,
        propertyInfo: node.value.propertyInfo
    )
    
    newReflectionInfo.cardinality = .zeroToMany(.dictionary(key: keyNode.value, value: valueNode.value))
    
    return Node(value: newReflectionInfo, children: valueNode.children)
}
