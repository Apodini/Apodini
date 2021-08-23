//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
