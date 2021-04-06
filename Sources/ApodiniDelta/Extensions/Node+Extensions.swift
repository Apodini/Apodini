//
//  File.swift
//  
//
//  Created by Eldi Cano on 20.03.21.
//

import Foundation

@_implementationOnly import ApodiniTypeReflection
@_implementationOnly import Runtime

// MARK: - ReflectionInfo Node extensions
extension Node where T == ReflectionInfo {
    // MARK: - Properties
    var isPrimitive: Bool {
        isSupportedScalarType(value.typeInfo.type)
    }

    var isEnum: Bool {
        value.typeInfo.kind == .enum
    }

    // MARK: - Functions
    func sanitized() -> Self {
        guard
            let sanitized = try?
                edited(handleOptional)?
                .edited(handleArray)?
                .edited(handleDictionary)?
                .edited(handlePrimitiveType)
        else { fatalError("Error occurred during transforming tree of nodes with type \(value.typeInfo.name).") }
        return sanitized
    }
}

extension TypeInfo {
    var schemaName: SchemaName {
        .init(String(reflecting: type))
    }
}
