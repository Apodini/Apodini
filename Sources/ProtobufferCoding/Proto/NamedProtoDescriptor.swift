//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2022 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// Describes some sort of proto descriptor which is able to represent a named type (e.g. message or enum)
public protocol NamedProtoDescriptor {
    /// The name of the descriptor.
    var name: String { get }
}

extension NamedProtoDescriptor {
    /// Retrieves the reflective swift type name from the type name mapping.
    /// - Parameters:
    ///   - schema: The schema on which the descriptor is located on.
    ///   - parentName: The name of all parent types. Those are used to build the full name of the descriptor.
    /// - Returns: Returns the type name of the associated swift type. Nil if the descriptor is synthesized.
    public func swiftTypeName(with schema: ProtoSchema, parentName: String) -> String? {
        let name = "\(parentName).\(self.name)"

        guard let swiftTypeName = schema.protoNameToSwiftTypeMapping[ProtoTypename(mangled: name)] else {
            fatalError("Reached inconsistent state where swift type name mapping isn't present for create Descriptor: Looked for '\(name)' of \(self)")
        }
        return swiftTypeName
    }
}

extension DescriptorProto: NamedProtoDescriptor {}

extension EnumDescriptorProto: NamedProtoDescriptor {}
