//
//  File.swift
//  
//
//  Created by Eldi Cano on 20.03.21.
//

import Foundation
@_implementationOnly import struct ApodiniTypeReflection.ReflectionInfo

class PropertyName: PropertyValueWrapper<String> {}
class PropertyOffset: PropertyValueWrapper<Int> {}

/// A property of a schema
struct SchemaProperty: Codable {
    /// Property name
    let name: PropertyName

    /// Offset of the property
    let offset: PropertyOffset

    /// Property type
    let type: PropertyType

    /// Schema name of property type
    let schemaName: SchemaName

    private init(name: String, offset: Int, type: PropertyType, schemaName: SchemaName) {
        self.name = .init(name)
        self.offset = .init(offset)
        self.type = type
        self.schemaName = schemaName
    }

    static func initialize(from reflectionInfo: ReflectionInfo, in builder: inout SchemaBuilder) -> SchemaProperty? {
        guard
            let name = reflectionInfo.propertyInfo?.name,
            let offset = reflectionInfo.propertyInfo?.offset,
            let schemaName = builder.build(for: reflectionInfo.typeInfo.type)
        else { return nil }

        let propertyType: PropertyType

        switch reflectionInfo.cardinality {
        case .zeroToOne:
            propertyType = .optional
        case .exactlyOne:
            propertyType = .exactlyOne
        case .zeroToMany(let collectionContext):
            switch collectionContext {
            case .array:
                propertyType = .array
            case .dictionary(key: let key, _):
                let primitiveType = PrimitiveType(key.typeInfo.type) ?? .string
                propertyType = .dictionary(key: primitiveType)
                builder.addSchema(.primitive(type: primitiveType))
            }
        }
        return .init(name: name, offset: offset, type: propertyType, schemaName: schemaName)
    }
}

// MARK: - Convenience
extension SchemaProperty {
    static func property(named: String, offset: Int, type: PropertyType, schemaName: SchemaName) -> SchemaProperty {
        .init(name: named, offset: offset, type: type, schemaName: schemaName)
    }

    static func enumCase(named: String, offset: Int) -> SchemaProperty {
        .init(name: named, offset: offset, type: .exactlyOne, schemaName: PrimitiveType.string.schemaName)
    }
}

// MARK: - Hashable
extension SchemaProperty: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(offset)
        hasher.combine(type)
    }
}

// MARK: - Equatable
extension SchemaProperty: Equatable {
    static func == (lhs: SchemaProperty, rhs: SchemaProperty) -> Bool {
        lhs.name == rhs.name
            && lhs.offset == rhs.offset
            && lhs.type == rhs.type
    }
}

// MARK: - ComparableObject
extension SchemaProperty: ComparableObject {
    var deltaIdentifier: DeltaIdentifier { .init(name.value) }

    func evaluate(result: ChangeContextNode, embeddedInCollection: Bool) -> Change? {
        guard let context = context(from: result, embeddedInCollection: embeddedInCollection) else {
            return nil
        }

        let changes = [
            name.change(in: context),
            offset.change(in: context),
            type.change(in: context),
            schemaName.change(in: context)
        ].compactMap { $0 }

        guard !changes.isEmpty else {
            return nil
        }

        return .compositeChange(location: Self.changeLocation, changes: changes)
    }

    func compare(to other: SchemaProperty) -> ChangeContextNode {
        ChangeContextNode()
            .register(compare(\.name, with: other), for: PropertyName.self)
            .register(compare(\.offset, with: other), for: PropertyOffset.self)
            .register(compare(\.type, with: other), for: PropertyType.self)
            .register(compare(\.schemaName, with: other), for: SchemaName.self)
    }
}
