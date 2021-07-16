//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation
import Apodini

/// Handle the `Foundation.UUID` type.
///
/// `UUID`s internal storage is a 16-tuple of `UInt8`. Its properties are not considered and the
/// type is handled separaretly.
/// - Parameter node: A `ReflectionInfo` node.
/// - Returns: A `ReflectionInfo` node.
public func handleUUID(_ node: Node<ReflectionInfo>) -> Node<ReflectionInfo> {
    node.value.typeInfo.type == UUID.self
        ? Node(value: node.value, children: [])
        : node
}
