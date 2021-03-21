//
//  File.swift
//  
//
//  Created by Eldi Cano on 20.03.21.
//

import Foundation

// MARK: - Cardinality Extension
extension ReflectionInfo.Cardinality {

    // MARK: - Properties
    var schemaNamePrefix: String {
        switch self {
        case .zeroToOne: return "_optional"
        case .zeroToMany(let context):
            switch context {
            case .dictionary: return "_dictionary"
            case .array:return "_array"
            }
        default: return ""
        }
    }
}

// MARK: - ReflectionInfo Node extensions
extension Node where T == ReflectionInfo {

    // MARK: - Properties
    var isPrimitive: Bool {
        let type = value.typeInfo.type
        return isSupportedScalarType(type) || type == UUID.self
    }

    var isEnum: Bool {
        value.typeInfo.kind == .enum
    }

    var rootName: String {
        return value.typeInfo.name + value.cardinality.schemaNamePrefix
    }

    // MARK: - Functions
    func sanitized() -> Self {
        guard
            let sanitized = try?
                edited(handleOptional)?
                .edited(handleArray)?
                .edited(handleDictionary)?
                .edited(handlePrimitiveType)?
                .edited(handleUUID)
        else { fatalError("Error occurred during transforming tree of nodes with type \(value.typeInfo.name).") }
        return sanitized
    }
}
