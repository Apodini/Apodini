//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniUtils
import ApodiniTypeReflection
@_implementationOnly import Runtime

extension ProtobufferMessage {
    init?(_ node: Node<Property?>) {
        // If a child is nil, there is a circle in theory.
        // Thus, this message is incomplete.
        // However, a complete message was built closer to the root of the tree.
        let properties = node.children.compactMap { $0.value }
        guard properties.count == node.children.count,
              let name = node.value?.typeName else {
            return nil
        }
        
        self.init(
            name: name,
            properties: Set(properties)
        )
    }
}

extension ProtobufferMessage.Property {
    init?(_ info: ReflectionInfo) throws {
        guard info.typeInfo.type != HandleArrayDidEncounterCircle.self else {
            return nil
        }
        
        let name = info.propertyInfo?.name ?? ""
        let typeName = try info.typeInfo.compatibleName()
        let uniqueNumber = info.propertyInfo?.offset ?? 0
        
        let fieldRule: FieldRule
        switch info.cardinality {
        case .zeroToOne:
            fieldRule = .optional
        case .exactlyOne:
            fieldRule = .required
        case .zeroToMany:
            fieldRule = .repeated
        }
        
        self.init(
            fieldRule: fieldRule,
            name: name,
            typeName: typeName,
            uniqueNumber: uniqueNumber
        )
    }
}

fileprivate extension TypeInfo {
    func compatibleName() throws -> String {
        if isSupportedScalarType(type) {
            return ApodiniUtils.mangledName(of: type).lowercased()
        } else {
            switch kind {
            case .struct, .class:
                return try compatibleGenericName() + "Message"
            case .tuple:
                return try tupleName() + "Message"
            default:
                throw ProtobufferInterfaceExporter.Error(message: "Kind: \(kind) is not supported")
            }
        }
    }
    
    func compatibleGenericName() throws -> String {
        String(describing: type)
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "<", with: "Of")
            .replacingOccurrences(of: ", ", with: "And")
    }

    func tupleName() throws -> String {
        if type == Void.self {
            return "Void"
        } else {
            throw ProtobufferInterfaceExporter.Error(message: "Tuple: \(type) is not supported")
        }
    }
}
