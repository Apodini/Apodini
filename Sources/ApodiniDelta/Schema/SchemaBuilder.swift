//
//  File.swift
//  
//
//  Created by Eldi Cano on 20.03.21.
//

import Foundation

/// Builds and holds the schemas of all types that it builds
struct SchemaBuilder {
    // MARK: - Properties
    private(set) var schemas: Set<Schema> = .empty

    // MARK: - Private functions
    private mutating func schema(from node: Node<ReflectionInfo>) -> Schema {
        let node = node.sanitized()
        let typeInfo = node.value.typeInfo
        let name = typeInfo.name

        if let existingSchema = schema(named: name) {
            return existingSchema
        }

        if node.isEnum {
            addSchema(.primitive(type: .string))
            return .enumeration(typeName: name, cases: typeInfo.cases.map { $0.name })
        }

        let properties: Set<SchemaProperty> = node.children
            .compactMap { .initialize(from: $0.sanitized().value, in: &self) }
            .unique()

        return node.isPrimitive
            ? .primitive(type: .init(typeInfo.type))
            : .complex(typeName: name, properties: properties)
    }

    // MARK: - Functions
    mutating func build(for type: Any.Type, root: Bool = true) -> SchemaReference? {
        guard let node = try? ReflectionInfo.node(type).sanitized() else {
            return nil
        }

        node.contextMap { schema(from: $0) }
            .collectValues()
            .save(in: &self)

        let schemaName = node.value.typeInfo.name
        if root, node.rootName != schemaName, let existing = schema(named: schemaName) {
            return updateName(of: existing, to: node.rootName)
        }

        return .init(schemaName: schemaName)
    }

    mutating func addSchema(_ schema: Schema) {
        schemas.insert(schema)
    }

    mutating func addSchemas(_ schemas: Set<Schema>) {
        self.schemas.formUnion(schemas)
    }

    mutating func updateName(of schema: Schema, to newName: String) -> SchemaReference {
        let updatedSchema = schema.updated(typeName: newName)
        schemas.remove(schema)
        addSchema(updatedSchema)
        return updatedSchema.reference
    }

    func schema(named: String) -> Schema? {
        schemas.first { $0.reference.schemaName == named }
    }
}
