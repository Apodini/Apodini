//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2022 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

// TODO fileNaming + docs!

public protocol NamedProtoDescriptor {
    var name: String { get }
}

extension NamedProtoDescriptor {
    // TODO signature!
    public func swiftTypeName(with schema: ProtoSchema, parentName: String) -> String? {
        let name = parentName + self.name

        guard let swiftTypeName = schema.protoNameToSwiftTypeMapping[ProtoTypename(mangled: name)] else {
            fatalError("Reached inconsistent state where swift type name mapping isn't present for create Descriptor: Looked for '\(name)' of \(self)")
        }
        return swiftTypeName
    }
}

extension DescriptorProto: NamedProtoDescriptor {}

extension EnumDescriptorProto: NamedProtoDescriptor {}
