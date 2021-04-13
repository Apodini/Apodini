//
//  File.swift
//  
//
//  Created by Eldi Cano on 20.03.21.
//

import Foundation
@_implementationOnly import struct ApodiniTypeReflection.ReflectionInfo

/// Builds and holds the schemas of all types that it builds
struct SchemaBuilder {
    // MARK: - Properties
    private(set) var schemas: Set<Schema> = .empty

    // MARK: - Private functions
    private mutating func schema(from node: Node<ReflectionInfo>) -> Schema {
        let node = node.sanitized()
        let typeInfo = node.value.typeInfo
        let schemaName = typeInfo.schemaName

        if let existingSchema = schema(named: schemaName) {
            return existingSchema
        }

        if node.isEnum {
            addSchema(.primitive(type: .string))
            return .enumeration(schemaName: schemaName, cases: typeInfo.cases.map { $0.name })
        }

        let properties: Set<SchemaProperty> = node.children
            .compactMap { .initialize(from: $0.sanitized().value, in: &self) }
            .unique()

        return node.isPrimitive
            ? .primitive(type: PrimitiveType(typeInfo.type) ?? .string)
            : .complex(schemaName: schemaName, properties: properties)
    }

    // MARK: - Functions
    mutating func build(for type: Any.Type) -> SchemaName? {
        guard let node = try? ReflectionInfo.node(type).sanitized() else {
            return nil
        }

        node.contextMap { schema(from: $0) }
            .collectValues()
            .save(in: &self)

        return node.value.typeInfo.schemaName
    }

    mutating func addSchema(_ schema: Schema) {
        schemas.insert(schema)
    }

    mutating func addSchemas(_ schemas: Set<Schema>) {
        self.schemas.formUnion(schemas)
    }

    func schema(named: SchemaName) -> Schema? {
        schemas.first { $0.schemaName == named }
    }
}
